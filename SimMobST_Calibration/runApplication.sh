LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/:/lib/x86_64-linux-gnu/:/usr/local/lib64/:

export LD_LIBRARY_PATH

echo "running $1"

$@
