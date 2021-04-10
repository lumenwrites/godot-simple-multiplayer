alias godot='/Applications/Godot.app/Contents/MacOS/Godot';
alias server='godot --path ~/projects/Gamedev/Godot/MPShooter/Server --position 1024,0 --resolution 300x300' ;
alias client1='godot /Applications/Godot.app/Contents/MacOS/Godot --path ~/projects/Gamedev/Godot/MPShooter/Client --position 0,0  --resolution 512x300 --always-on-top -dev';
alias client2='godot /Applications/Godot.app/Contents/MacOS/Godot --path ~/projects/Gamedev/Godot/MPShooter/Client --position 512,0  --resolution 512x300 --always-on-top -dev';
# Redirect the stdout and stderr to /dev/null to ignore the output.
# Use trap to be able to kill all commands with 1 ctrl-c
(trap 'kill 0' SIGINT; server & sleep .5 && client1 > /dev/null & sleep 1 && client2 > /dev/null);


