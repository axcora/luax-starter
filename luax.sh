case "$1" in
    start)
        lua55 start.lua
        ;;
    build)
        lua55 build.lua
        ;;
    all)
        lua55 build.lua
        lua55 start.lua
        ;;
    *)
        echo "Usage: ./luax.sh [command]"
        echo ""
        echo "Commands:"
        echo "  build  - Build static site"
        echo "  start  - Start HTTP server"
        echo "  all    - Build + Start"
        echo ""
        echo "Example:"
        echo "  ./luax.sh build"
        echo "  ./luax.sh start"
        echo "  ./luax.sh all"
        ;;
esac