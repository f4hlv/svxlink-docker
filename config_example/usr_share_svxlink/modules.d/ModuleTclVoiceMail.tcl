###############################################################################
#
# TclVoiceMail module implementation
#
###############################################################################

#
# This is the namespace in which all functions and variables below will exist.
# The name must match the configuration variable "NAME" in the
# [ModuleTclVoiceMail] section in the configuration file. The name may be
# changed but it must be changed in both places.
#
namespace eval TclVoiceMail {

#
# Check if this module is loaded in the current logic core
#
if {![info exists CFG_ID]} {
  return;
}

#
# Extract the module name from the current namespace
#
set module_name [namespace tail [namespace current]];

#
# The user id of the currently logged in user
#
set userid "";

#
# The recepient of a message being recorded.
#
set rec_rcpt "";

#
# The current state of the VoiceMail module
#
set state "idle";

#
# The directory where the voice mails are stored
#
set recdir "/var/spool/svxlink/voice_mail";

#
# The default mail server
#
set mail_smtp_url "smtp://127.0.0.1:25";

#
# Configuration file names
#
set cfg_etc "/etc/svxlink/TclVoiceMail.conf";
set cfg_home ""
if {[info exists ::env(HOME)]} {
  set cfg_home "$env(HOME)/.svxlink/TclVoiceMail.conf";
}


#
# Default maximum recording times. Set them from config variables if
# available.
#
set max_subj_time 10000
set max_mesg_time 120000


#
# A convenience function for printing out information prefixed by the
# module name
#
#   msg - The message to print
#
proc printInfo {msg} {
  variable module_name;
  puts "$module_name: $msg";
}


#
# A convenience function for calling an event handler
#
#   ev - The event string to execute
#
proc processEvent {ev} {
  variable module_name
  ::processEvent "$module_name" "$ev"
}


#
# Read configuration file
#
if {$cfg_home != "" && [file exists $cfg_home]} {
  source $cfg_home;
} elseif [file exists $cfg_etc] {
  source $cfg_etc;
} else {
  set info_str "*** ERROR: Could not find a configuration file in module \"$module_name\". Tried"
  if {$cfg_home != ""} {
    set info_str "$info_str \"$cfg_home\" and"
  }
  set info_str "$info_str \"$cfg_etc\""
  printInfo "$info_str"
  exit 1;
}


#
# Check if the spool directory is writable
#
if {[file writable $recdir] != 1} {
  printInfo "*** ERROR: The spool directory ($recdir) is not writable by the current user or does not exist.";
  exit 1;
}


#
# Read the specified user configuration variable for the specified user ID
#
#   id  - User ID
#   var - The name of the user variable to read
#
proc id2var {id var} {
  variable users;
  array set user [split $users($id) " ="];
  if {[array names user -exact $var] != ""} {
    return $user($var);
  } else {
    return "";
  }
}


#
# Executed when this module is being activated
#
proc activateInit {} {
  setState "login"
}


#
# Executed when this module is being deactivated.
#
proc deactivateCleanup {} {
  variable userid
  abortRecording
  set userid ""
  setState "idle"
}


#
# Executed when a DTMF digit (0-9, A-F, *, #) is received
#
#   char - The received DTMF digit
#   duration - The duration of the received DTMF digit
#
proc dtmfDigitReceived {char duration} {
}


#
# Executed when a DTMF command is received
#
#   cmd - The received DTMF command
#
proc dtmfCmdReceived {cmd} {
  variable state;
  
  if {$state == "login"} {
    cmdLogin $cmd;
  } elseif {$state == "logged_in"} {
    if {$cmd == ""} {
      deactivateModule;
    } elseif {$cmd == "0"} {
      logged_in_menu_help
    } elseif {$cmd == "1"} {
      cmdPlayNextNewMessage $cmd;
    } elseif {[regexp {^2} $cmd]} {
      cmdRecordMessage $cmd;
    } else {
      processEvent "logged_in_unknown_command $cmd"
    }
  } elseif {[regexp {^rec_\w+} $state]} {
    cmdRecordMessage $cmd;
  } elseif {[regexp {^pnm_\w+} $state]} {
    cmdPlayNextNewMessage $cmd;
  } else {
    printInfo "*** ERROR: Encountered unknown state \"$state\""
    processEvent "module_error"
    deactivateModule
  }
}


#
# Executed when a DTMF command is received in idle mode. That is, a command is
# received when this module has not been activated first.
#
#   cmd - The received DTMF command
#
proc dtmfCmdReceivedWhenIdle {cmd} {
  variable recdir;
  variable users;

  if {[array names users -exact "$cmd"] == ""} {
    processEvent "idle_unknown_userid $cmd"
    return;
  }

  set call [id2var $cmd call];
  set subjects [glob -nocomplain -directory "$recdir/$call" *_subj.wav];
  set msg_cnt [llength $subjects];
  processEvent "idle_announce_num_new_messages_for $call $msg_cnt"
}


#
# Executed when the squelch open or close.
#
#   is_open - Set to 1 if the squelch is open otherwise it's set to 0
#
proc squelchOpen {is_open} {
  variable state;
  variable recdir;
  variable rec_rcpt;
  variable rec_timestamp;
  variable userid;
  variable mail_smtp_url;
  variable mail_from_addr;
  variable mail_from_name;
  variable mail_subj;
  variable mail_msg;
  variable CFG_ID;
  variable ::Logic::CFG_CALLSIGN;
  variable max_subj_time;
  variable max_mesg_time;
  
  if {$state == "rec_subject"} {
    if {$is_open} {
      set rec_rcpt_call [id2var $rec_rcpt call];
      set subj_filename "$recdir/$rec_rcpt_call/$rec_timestamp";
      append subj_filename "_$userid\_subj.wav";
      printInfo "Recording subject to file: $subj_filename";
      recordStart $subj_filename $max_subj_time;
    } else {
      recordStop;
      processEvent "rec_message"
      setState "rec_message";
    }
  } elseif {$state == "rec_message"} {
    set rec_rcpt_call [id2var $rec_rcpt call];
    set subj_filename "$recdir/$rec_rcpt_call/$rec_timestamp";
    append subj_filename "_$userid\_subj.wav";
    set mesg_filename "$recdir/$rec_rcpt_call/$rec_timestamp";
    append mesg_filename "_$userid\_mesg.wav";
    if {$is_open} {
      printInfo "Recording message to file: $mesg_filename";
      recordStart $mesg_filename $max_mesg_time;
    } else {
      recordStop;
      processEvent "rec_done"
      set email [id2var $rec_rcpt email];
      if {$email != ""} {
        printInfo "Sending notification e-mail to \"$email\"";
      	eval set msg \"$mail_msg\";
      	#exec mail -s "$mail_subj" $email -- -f $mail_from_addr \
	#	-F "$mail_from_name" << "$msg" &;
      	exec mutt -s "$mail_subj" $email \
		-e "set from=\"$mail_from_addr\"" \
		-e "set realname=\"$mail_from_name\"" \
                -e "set smtp_url=\"$mail_smtp_url\"" \
		<< "$msg" &;
      }
      set rec_rcpt "";
      setState "logged_in";
    }
  }
}


#
# Executed when all announcement messages has been played.
# Note that this function also may be called even if it wasn't this module
# that initiated the message playing.
#
proc allMsgsWritten {} {
}


#
# Set a new state
#
#   new_state - The new state to set
#
proc setState {new_state} {
  variable state $new_state
}


#
# State "login" command handler
#
#   cmd - The received command
#
proc cmdLogin {cmd} {
  variable recdir;
  variable userid;
  variable users;
  variable state;
  
  if {$cmd == ""} {
    printInfo "Aborting login"
    processEvent "login_aborted"
    deactivateModule
    return;
  }
  
  set userid [string range $cmd 0 2];
  if {[array names users -exact "$userid"] != ""} {
    array set user [split $users($userid) " ="];
    set passwd [string range $cmd 3 end];
    if {$passwd == $user(pass)} {
      printInfo "User $user(call) logged in with password $user(pass)";
      processEvent "login_ok $user(call)"
      if {[file exists "$recdir/$user(call)"] != 1} {
        file mkdir "$recdir/$user(call)";
      }
      setState "logged_in";
    } else {
      printInfo "Wrong password ($passwd) for user $user(call)";
      processEvent "login_failed_wrong_password $user(call) $userid $passwd"
    }
  } else {
    printInfo "Could not find user id $userid"
    processEvent "login_failed_unknown_userid $userid"
  }
}


#
# State "play next message" command handler
#
#   cmd - The received command
#
proc cmdPlayNextNewMessage {cmd} {
  variable recdir;
  variable userid;
  variable state;

  set call [id2var $userid call];
  set subjects [glob -nocomplain -directory "$recdir/$call" *_subj.wav];
  set subjects [lsort -ascii -increasing $subjects];
  if {$state == "logged_in"} {
    set msg_cnt [llength $subjects];
    printInfo "$msg_cnt new messages for $call";
    if {$msg_cnt > 0} {
      regexp {^(.*)_subj.wav} [lindex $subjects 0] -> basename
      processEvent "play_next_new_message $msg_cnt $basename"
      setState "pnm_menu";
    } else {
      processEvent "play_next_new_message $msg_cnt"
    }
  } elseif {$state == "pnm_menu"} {
    regexp {^(.*)_subj.wav} [lindex $subjects 0] -> basename
    if {$cmd == "0"} {
      processEvent "pnm_menu_help"
    } elseif {$cmd == "1"} {
      printInfo "Deleting message $basename";
      file delete "$basename\_subj.wav" "$basename\_mesg.wav";
      processEvent "pnm_delete"
      setState "logged_in";
    } elseif {$cmd == "2"} {
      printInfo "Reply to and delete message $basename";
      file delete "$basename\_subj.wav" "$basename\_mesg.wav";
      processEvent "pnm_reply_and_delete"
      regexp {\d{8}_\d{6}_(\d+)$} $basename -> sender;
      setState "rec_reply";
      cmdRecordMessage "x$sender";
    } elseif {$cmd == "3"} {
      printInfo "Replay message $basename";
      processEvent "pnm_play_again $basename"
    } elseif {$cmd == ""} {
      printInfo "Aborted operation play next message";
      processEvent "pnm_aborted"
      setState "logged_in";
    } else {
      printInfo "Unknown command: $cmd";
      processEvent "pnm_unknown_command $cmd"
    }
  }
}


#
# Abort the current recording. If no recording is active nothing is done.
#
proc abortRecording {} {
  variable recdir;
  variable rec_rcpt;
  variable rec_timestamp;
  variable userid;

  if {$rec_rcpt != ""} {
    printInfo "Aborted recording";
    set rec_rcpt_call [id2var $rec_rcpt call];
    set subj_filename "$recdir/$rec_rcpt_call/$rec_timestamp";
    append subj_filename "_$userid\_subj.wav";
    set mesg_filename "$recdir/$rec_rcpt_call/$rec_timestamp";
    append mesg_filename "_$userid\_mesg.wav";
    file delete $subj_filename $mesg_filename;
    set rec_rcpt "";
  }
}


#
# State "record message" command handler
#
#   cmd - The received command
#
proc cmdRecordMessage {cmd} {
  variable state;
  variable users;
  variable rec_rcpt;
  variable recdir;
  variable rec_timestamp;
  variable userid;
  
  if {($state == "logged_in") || ($state == "rec_reply")} {
    set rec_timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"];
    setState "rec_rcpt";
    if {[string length $cmd] == 1} {
      processEvent "rec_enter_rcpt"
    } else {
      cmdRecordMessage [string range $cmd 1 end];
    }
  } elseif {$state == "rec_rcpt"} {
    if {$cmd == ""} {
      printInfo "Aborted operation send new message";
      processEvent "rec_aborted"
      setState "logged_in";
    } elseif {[array names users -exact "$cmd"] != ""} {
      array set user [split $users($cmd) " ="];
      printInfo "Sending voice mail to $user(call)";
      processEvent "rec_sending_to $user(call)"
      set rec_rcpt $cmd;
      set rec_rcpt_call [id2var $rec_rcpt call];
      if {[file exists "$recdir/$rec_rcpt_call"] != 1} {
        file mkdir "$recdir/$rec_rcpt_call";
      }
      setState "rec_subject";
    } else {
      printInfo "Could not find user id $cmd"
      processEvent "rec_enter_rcpt_unknown_userid $cmd"
    }
  } else {
    processEvent "rec_aborted"
    abortRecording
    setState "logged_in"
  }
}


# end of namespace
}


#
# This file has not been truncated
#
