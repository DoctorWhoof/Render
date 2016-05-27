
Import render

#GLFW_WINDOW_FULLSCREEN = False
#GLFW_WINDOW_RESIZABLE = True
#GLFW_WINDOW_RENDER_WHILE_RESIZING = True

' ************************** For easy results, build and launch in Desktop target (GLFW) **************************
' ********************** In HTML5, it's necessary to edit the .html file and set CANVAS_RESIZE_MODE=2 *************

Function Main();
	New RenderTest
End

Class RenderTest extends App

	Field width:= 160
	Field height:= 120

	Method OnCreate()
		Render.SetResolution( width, height, False )	'Virtual resolution, usage is ( width, height, imageFiltering )
		Render.renderToTexture = True					'Causes all rendering to be performed on a texture that is resized then drawn
		Render.enforceAspectRatio = True				'Masks out areas of the image beyond the aspect of the original width and height			
		Render.integerScaling = True					'Forces te scaling to integer values, great for pixel art but causes black bars around screen
		Render.bgColor = [ 0.2, 0.25, 0.3 ]				'RGB values for background
		Render.debug = True								'Prints information on screen
	End
	
	Method OnUpdate()
		'Input handling
		If KeyDown( KEY_LEFT )	Then Render.camera.x -= 1
		If KeyDown( KEY_RIGHT ) Then Render.camera.x += 1
		If KeyDown( KEY_UP )	Then Render.camera.y -= 1
		If KeyDown( KEY_DOWN )	Then Render.camera.y += 1
		If KeyHit( KEY_A )		Then Render.enforceAspectRatio = Not Render.enforceAspectRatio
		If KeyHit( KEY_S )		Then Render.integerScaling = Not Render.integerScaling
		If KeyHit( KEY_T )		Then Render.renderToTexture = Not Render.renderToTexture
	End

	Method OnRender()
		Render.StartFrame()
		
		local halfWidth := width/2
		local halfHeight := height/2
		
		'Bottom layer, parallax = 0.25
		Render.StartLayer( 0.25 )
		Render.canvas.SetColor( 0.35, 0.45, 0.55 )
		For Local x:int = -halfWidth To halfWidth Step 2;
			Render.canvas.DrawLine( x, -halfHeight, x, halfHeight );
		End
		For Local y:int = -halfHeight To halfHeight Step 2;
			Render.canvas.DrawLine( -halfWidth, y, halfWidth, y );
		End
		Render.FinishLayer()
		
		'Top layer, parallax =1.0
		Render.StartLayer( 1.0 )
		Render.canvas.SetColor( 1.0, 0.65, 0 )
		Render.canvas.DrawCircle( 0, 0, Render.height/4 )
		Render.canvas.SetColor( 1.0, 1.0, 1.0 )
		Render.canvas.DrawPoint( 0, 0 )
		Render.FinishLayer()
		
		'Prints info on screen
		Render.Print( "Virtual Dimensions:	" + Render.width + "," + Render.height )
		Render.Print( "Real Dimensions:		" + DeviceWidth + "," + DeviceHeight )
		Render.Print( "Mouse (World):		" + Render.mouseX + "," + Render.mouseY )
		Render.Print( "Mouse (Screen):		" + Int( MouseX ) + "," + Int( MouseY ) )
		Render.Print( "Camera:				" + Render.camera.x + "," + Render.camera.y )
		Render.Print( "Scale: 				" + String(Render.scale)[..4] )
		Render.Print( "Crop Size:			" + Render.cropWidth + "," + Render.cropHeight )
		Render.Print( "Aspect ratio is		" + String( Render.aspectRatio )[..4] )
		Render.Print( "" )
		Render.Print( "Hit A to toggle aspect ratio enforcement" )
		Render.Print( "Hit S to toggle integer scaling" )
		Render.Print( "Hit T to toggle Render to texture" )
		Render.Print( "Hit Cursor keys to move the camera" )
		Render.Print( "(Aspect is always enforced if renderToTexture = True)" )
		
		Render.FinishFrame()
	End
	
End