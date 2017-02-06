$dir = ("c:" + ("$($args[0])".Substring(2) -replace "/", "\"))

New-Item -Path "$dir\TEST.txt"
