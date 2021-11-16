state("NuclearBlaze","1.0.3")
{
    int frame_timer : "libhl.dll", 0x55FF0, 0x9B8, 0x8, 0x30, 0x140; //contains the timers in frames
    int X_position : "libhl.dll", 0x55FF0, 0x9C0, 0x0, 0x30, 0xC8, 0xC8, 0x34 //contains X position of the player
}

isLoading{
    return true;
}

gameTime {
    return TimeSpan.FromSeconds((double)current.frame_timer/30); //we divide the number of frames by 30 to get current time in seconds
}

//runs at the start of the game
init
{

    //MD5 checksum code adapted from Zment's Defy Gravity and R30hedron Dead Cells autosplitter
    byte[] exeMD5HashBytes = new byte[0];
    using (var md5 = System.Security.Cryptography.MD5.Create())
    {
        using (var s = File.Open(modules.First().FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
        {
            exeMD5HashBytes = md5.ComputeHash(s);
        }
    }
    
    var MD5Hash = exeMD5HashBytes.Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
    vars.MD5Hash = MD5Hash;
    print("MD5: " + MD5Hash);

    switch(MD5Hash){
        case "A29F2A7945A11B5E25F3B563DF9ACA0E" :
            version = "1.0.3";
            break;
        default :
            version = "Unknown Version";
            MessageBox.Show(timer.Form,
                "Dead Cells Autosplitter Error:\n\n"
                + "This autosplitter does not support this game version.\n"
                + "Please contact Evian (@Evian#6930 on Discord)\n"
                + "with the following string and the game's version number.\n\n"
                + "MD5Hash: " + MD5Hash + "\n\n"
                + "Defaulting to the most recent known memory addesses...",
                  "Dead Cells Autosplitter Error",
                  MessageBoxButtons.OK,
                  MessageBoxIcon.Error);
            break;
    }
    
    //getting save folder path
    vars.saves_folder = ((modules.First().FileName).Replace("\\","/")).Replace("dx64/NuclearBlaze.exe","save/");
    
    // we are reading the game saves at game start, which contains current level ID
    vars.old_reader_1 = new StreamReader(new FileStream(  (vars.saves_folder+"slot0.dnsav") , FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.old_save_1 = vars.old_reader_1.ReadLine();
    vars.old_reader_2 = new StreamReader(new FileStream( (vars.saves_folder+"slot1.dnsav") , FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.old_save_2 = vars.old_reader_2.ReadLine();
    vars.old_reader_3 = new StreamReader(new FileStream( (vars.saves_folder+"slot2.dnsav") , FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.old_save_3 = vars.old_reader_3.ReadLine();
}

//always running
//when returning true, starts the timer
start{
    //when starting the timer, we are making sure the two versions of the save files are the same
    vars.old_save_1 = vars.new_save_1;
    vars.old_save_2 = vars.new_save_2;
    vars.old_save_3 = vars.new_save_3;

    return old.frame_timer == 0 && current.frame_timer > 0;
}

//always running 
//when returning true, reset the timer
reset{
    return current.frame_timer == -1;
}

//always running
update{
    
    //while the game is running we are reading the saves
    vars.new_reader_1 = new StreamReader(new FileStream( (vars.saves_folder+"slot0.dnsav") , FileMode.Open, FileAccess.Read, FileShare.ReadWrite) );
    vars.new_save_1 = vars.new_reader_1.ReadLine();
    vars.new_reader_2 = new StreamReader(new FileStream( (vars.saves_folder+"slot1.dnsav") , FileMode.Open, FileAccess.Read, FileShare.ReadWrite) );
    vars.new_save_2 = vars.new_reader_2.ReadLine();
    vars.new_reader_3 = new StreamReader(new FileStream( (vars.saves_folder+"slot2.dnsav") , FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.new_save_3 = vars.new_reader_3.ReadLine();
 
}

//always running
//when returning true, split
split{
    //if one of the save file changed, that means current level ID has been updated -> we changed level
    var save_1_changed = vars.old_save_1 != vars.new_save_1;
    var save_2_changed = vars.old_save_2 != vars.new_save_2;
    var save_3_changed = vars.old_save_3 != vars.new_save_3;

    //if we are in the last screen, the save file contains the string Ending
    var last_level_1 = vars.new_save_1.Contains("Ending");
    var last_level_2 = vars.new_save_2.Contains("Ending");
    var last_level_3 = vars.new_save_3.Contains("Ending");

    //if we are far enough in the right, it means we touched the final door
    var touched_door = current.X_position > 24;

    
    //if level changed, we copy the new save into the old one then we split
    if(save_1_changed || save_2_changed || save_3_changed){
        vars.old_save_1 = vars.new_save_1;
        vars.old_save_2 = vars.new_save_2;
        vars.old_save_3 = vars.new_save_3;
        
        return true;
    }

    //if we are in the last level AND we are far enough in the right, we split (last split)
    if( (last_level_1 && touched_door) || (last_level_2 && touched_door) || (last_level_3 && touched_door)   ){
        return true;
    }
    
    
}
