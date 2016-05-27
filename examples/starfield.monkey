#GLFW_WINDOW_FULLSCREEN = False
#GLFW_WINDOW_RESIZABLE = True
#GLFW_WINDOW_RENDER_WHILE_RESIZING = True

Import render

Function Main();
	New Starfield
End

Class Starfield extends App

	Global width:= 1920.0, height:= 1080.0
	Global halfWidth:Float, halfHeight:Float
	
	Global maxStars := 20000
	Global acceleration := 1.02
	
	Global minFade := 0.1
	Global fadeAcc := 0.05
	
	Private
	Field stars := New Stack<Star>

	Public
	Method OnCreate()
		Render.SetResolution( width, height, True )
		Render.SetFrameRate( 30 )
		Render.renderToTexture = False
		Render.enforceAspectRatio = False
		Render.integerScaling = False
		halfWidth = width/2.0
		halfHeight = height/2.0
		For Local n := 1 To maxStars
			Local star := New Star
			star.Reset()
			star.z = Rnd( 1.0, 10.0 )
			stars.Push( star )
		Next
	End
	
	Method OnUpdate()
		If KeyHit( KEY_MINUS ) Then acceleration *= 0.9995
		If KeyHit( KEY_EQUALS ) Then acceleration *= 1.0025
		For Local star := Eachin stars
			star.Update()
		Next
	End

	Method OnRender()
		Render.StartFrame()
		Render.StartLayer( 1.0 )
		For Local star := Eachin stars
			star.Plot()
		Next
		Render.FinishLayer()
		Render.FinishFrame()
	End
	
End


Class Star
	Field x:Float, y:Float, z:Float
	Field startX:Float, startY:Float
	Field oldX:Float, oldY:Float
	Field color:Float[]
	Field mult:Float
	
	Method Plot()
		Render.canvas.SetColor( color[0]*mult, color[1]*mult, color[2]*mult )
		Render.canvas.DrawLine( x, y, oldX, oldY )
	End
	
	Method Update()
		z *= Starfield.acceleration
		mult += Starfield.fadeAcc
		If mult > 1.0 Then mult = 1.0
		oldX = x
		oldY = y
		x = startX * z
		y = startY * z
		If ( x > Starfield.width ) Or ( x < -Starfield.width ) Or ( y > Starfield.height ) Or ( y < -Starfield.height )
			Reset()
		End
	End
	
	Method Reset()
		z = 1
		mult = Starfield.minFade
		startX = Rnd( -Starfield.halfWidth, Starfield.halfWidth )
		startY = Rnd( -Starfield.halfHeight, Starfield.halfHeight )
		x = startX
		y = startY
		oldX = x
		oldY = y
		Local bright := Rnd( 0.2, 1.0 )
		color = [ Rnd( 0.25, 0.5 ) * bright, Rnd( 0.5, 0.8 ) * bright, Rnd( 0.8, 1.0 ) * bright ]
	End
End