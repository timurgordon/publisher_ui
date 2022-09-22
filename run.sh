rm -rf public static/css
./tailwindcss -i src/index.css -o ./static/css/index.css --minify 
v . -g
./publisher_ui -g
