{ -*- buffer-read-only: t -*- }
{ DON'T EDIT -- this file was automatically generated from "edge_detect.glsl" }
'int screen_x();' + LineEnding + 
'int screen_y();' + LineEnding + 
'vec4 screen_get_color(ivec2 position);' + LineEnding + 
'' + LineEnding + 
'void main (void)' + LineEnding + 
'{' + LineEnding + 
'  vec4 left   = screen_get_color(ivec2(screen_x() - 1, screen_y()));' + LineEnding + 
'  vec4 right  = screen_get_color(ivec2(screen_x() + 1, screen_y()));' + LineEnding + 
'  vec4 top    = screen_get_color(ivec2(screen_x(), screen_y() - 1));' + LineEnding + 
'  vec4 bottom = screen_get_color(ivec2(screen_x(), screen_y() + 1));' + LineEnding + 
'  gl_FragColor = (abs(left - right) + abs(top - bottom)) / 2.0;' + LineEnding + 
'}' + LineEnding + 
''
