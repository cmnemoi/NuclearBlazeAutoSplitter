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

    //MD5 checksum code adapted from Zment's Defy Gravity and R30hedron's Dead Cells autosplitters
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
                "Nuclear Blaze Autosplitter Error:\n\n"
                + "This autosplitter does not support this game version.\n"
                + "Please contact Evian (@Evian#6930 on Discord)\n"
                + "with the following string and the game's version number.\n\n"
                + "MD5Hash: " + MD5Hash + "\n\n"
                + "Defaulting to the most recent known memory addesses...",
                  "Nuclear Blaze Autosplitter Error",
                  MessageBoxButtons.OK,
                  MessageBoxIcon.Error);
            break;
    }
    
    //getting save folder path
    vars.saves_folder = ((modules.First().FileName).Replace("\\","/")).Replace("dx64/NuclearBlaze.exe","save/");
    
    // we are reading the game saves at game start, which contains current level ID
    vars.save_reader = new List<StreamReader>();
    vars.old_save = new List<string>();
    vars.new_save = new List<string>();

    for(var i = 0; i < 3; i++) 
    {
        vars.save_reader.Add(new StreamReader(new FileStream(vars.saves_folder+"slot" + i.ToString() + ".dnsav", FileMode.Open, FileAccess.Read, FileShare.ReadWrite)));
        vars.old_save.Add(vars.save_reader[i].ReadLine());
        vars.new_save.Add(vars.old_save[i]);
    }

    vars.levelId = "Intro_forest";
    vars.old_levelId = "Intro_forest";
    vars.current_save_id = -1;

    vars.settings_reader = new StreamReader(new FileStream(vars.saves_folder+"settings.dnsav", FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
}

//always running
//when returning true, starts the timer
start{
    //when starting the timer, we are making sure the two versions of the save files are the same
    for(var i = 0; i < 3; i++) 
    {
        vars.old_save[i] = vars.new_save[i];
    }

    vars.levelId = "Intro_forest";
    vars.old_levelId = "Intro_forest";

    vars.settings_reader.DiscardBufferedData();
    vars.settings_reader.BaseStream.Seek(0, System.IO.SeekOrigin.Begin);
    while (!vars.settings_reader.EndOfStream) {
        var line = vars.settings_reader.ReadLine();
        if (line.Contains("curSaveSlot")) {
            var start_pos = line.IndexOf(":") + 1;
            var end_pos = line.IndexOf(",");
            var curSaveSlotStr = line.Substring(start_pos, end_pos - start_pos);
            var old_save_id = vars.current_save_id;
            vars.current_save_id = Int32.Parse(curSaveSlotStr);
            if (!vars.current_save_id.Equals(old_save_id)) {
                print("Current save id found: " + vars.current_save_id.ToString());
            }
            break;
        }
    }

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
    if (vars.current_save_id != -1) {
        vars.old_save[vars.current_save_id] = vars.new_save[vars.current_save_id];

        // Discard buffered data and seek to the start of the stream before reading it
        vars.save_reader[vars.current_save_id].DiscardBufferedData();
        vars.save_reader[vars.current_save_id].BaseStream.Seek(0, System.IO.SeekOrigin.Begin);
        vars.new_save[vars.current_save_id] = vars.save_reader[vars.current_save_id].ReadLine();

        if (vars.old_save[vars.current_save_id] != vars.new_save[vars.current_save_id]) {
            // Read Nuclear Blaze save format
            var LEVEL_ID_LABEL = "y7:levelId";
            var current_save = vars.new_save[vars.current_save_id];
            int idx_lvlId_label = current_save.IndexOf(LEVEL_ID_LABEL);
            if (idx_lvlId_label > -1) {
                if(current_save[idx_lvlId_label + LEVEL_ID_LABEL.Length] != 'n') {
                    // +10 to skip the y7:levelId, +1 to skip the y
                    var save_substring = current_save.Substring(idx_lvlId_label + LEVEL_ID_LABEL.Length + 1); 
                    // save_substring should look like this "12:Intro_foresty11:gameVersiony5:1.0.3y4:diffoy[...]"
                    var idx_lvlId_label_length = save_substring.IndexOf(":"); // in that example, should give us 2
                    var levelId_length_str = save_substring.Substring(0, idx_lvlId_label_length); // in that example, should give us "12"
                    int levelId_length = Int32.Parse(levelId_length_str); // should be 12
                    
                    vars.old_levelId = vars.levelId;
                    vars.levelId = save_substring.Substring(idx_lvlId_label_length + 1, levelId_length); // should be Intro_forest
                    print("Save changed");
                }
            }
        }
    }
}

//always running
//when returning true, split
split{
    if (vars.current_save_id == -1) {
        return;
    }

    //if level changed, we copy the new save into the old one then we split
    if (!vars.old_levelId.Equals(vars.levelId)) 
    {
        print("SPLIT - Current level id: " + vars.levelId.ToString() + ", old level id: " + vars.old_levelId.ToString());
        vars.old_levelId = vars.levelId;
        return true;
    }

    //if we are far enough in the right, it means we touched the final door
    var touched_door = current.X_position > 24;

    //if we are in the last level AND we are far enough in the right, we split (last split)
    if (vars.levelId.Equals("Ending") && touched_door) {
        print("SPLIT - Ending level id: " + vars.levelId.ToString() + ", touched door");
        return true;
    }
}
