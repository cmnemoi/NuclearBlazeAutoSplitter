state("NuclearBlaze")
{
    int frame_timer : "libhl.dll", 0x55FF0, 0x9B8, 0x8, 0x30, 0x140;
}

isLoading{
    return true;
}

gameTime {

        return TimeSpan.FromSeconds((double)current.frame_timer/30);
}
   
init
{
    
}

start{
    return old.frame_timer == 0 && current.frame_timer > 0 && current.frame_timer > 0.1;
}

reset{
    return current.frame_timer == Int32.MaxValue;
}
update{
    print(""+current.frame_timer);
}
