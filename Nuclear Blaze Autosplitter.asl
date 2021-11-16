state("NuclearBlaze")
{
    int frame_timer : "libhl.dll", 0x55FF0, 0x9B8, 0x8, 0x30, 0x140; //contains the timers in frames
}

isLoading{
    return true;
}

gameTime {
    return TimeSpan.FromSeconds((double)current.frame_timer/30); //we divide the number of frames by 30 to get current time in seconds
}
   
init
{
    
    //we are reading the game saves at game starting, which contains current level ID
    vars.old_reader_1 = new StreamReader(new FileStream("C:/Program Files (x86)/Steam/steamapps/common/Nuclear Blaze/save/slot0.dnsav", FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.old_save_1 = vars.old_reader_1.ReadLine();
    vars.old_reader_2 = new StreamReader(new FileStream("C:/Program Files (x86)/Steam/steamapps/common/Nuclear Blaze/save/slot1.dnsav", FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.old_save_2 = vars.old_reader_2.ReadLine();
    vars.old_reader_3 = new StreamReader(new FileStream("C:/Program Files (x86)/Steam/steamapps/common/Nuclear Blaze/save/slot2.dnsav", FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.old_save_3 = vars.old_reader_3.ReadLine();
}

start{
    //when starting the timer, we are making sure the two versions of the save files are the same
    vars.old_save_1 = vars.new_save_1;
    vars.old_save_2 = vars.new_save_2;
    vars.old_save_3 = vars.new_save_3;

    return old.frame_timer == 0 && current.frame_timer > 0;
}

reset{
    return current.frame_timer == -1;
}
update{
    
    //while the game is running we are reading the saves
    vars.new_reader_1 = new StreamReader(new FileStream("C:/Program Files (x86)/Steam/steamapps/common/Nuclear Blaze/save/slot0.dnsav", FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.new_save_1 = vars.new_reader_1.ReadLine();
    vars.new_reader_2 = new StreamReader(new FileStream("C:/Program Files (x86)/Steam/steamapps/common/Nuclear Blaze/save/slot1.dnsav", FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.new_save_2 = vars.new_reader_2.ReadLine();
    vars.new_reader_3 = new StreamReader(new FileStream("C:/Program Files (x86)/Steam/steamapps/common/Nuclear Blaze/save/slot2.dnsav", FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.new_save_3 = vars.new_reader_3.ReadLine();

 
}
split{
    //if one of the save file changed, that means current level ID has been updated -> we changed level
    var save_1_changed = vars.old_save_1 != vars.new_save_1;
    var save_2_changed = vars.old_save_2 != vars.new_save_2;
    var save_3_changed = vars.old_save_3 != vars.new_save_3;
    
    //if level changed, we copy the new save into the old one then we split
    if(save_1_changed || save_2_changed || save_3_changed){
        vars.old_save_1 = vars.new_save_1;
        vars.old_save_2 = vars.new_save_2;
        vars.old_save_3 = vars.new_save_3;

        return true;
    }
    
    
}
