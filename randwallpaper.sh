file1=`find ~/images -maxdepth 1 -name '*.*' | sort -R  | head -1`
file2=`find ~/images -maxdepth 1 -name '*.*' -not -name '$file1' | sort -R  | head -1`
DISPLAY=:0 feh --bg-fill $file1 $file2
