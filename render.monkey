
Import mojo2
Import vector
Import useful

Class Render

	Global width 				:= 320.0
	Global height 				:= 240.0

	Global camera				:= New Rect				'Camera coordinates

	Global enforceAspectRatio	:= False				'Adjusts width to preserve aspectRatio
	Global integerScaling 		:= False				'Forces scaling to integer numbers (good for pixel art)
	Global filterTextures 		:= Image.Filter			'Set to 0 to disable

	Global renderToTexture 		:= False				'Setting to true will render to a texture, then scale it up to fill the screen
	Global canvas				:Canvas 				'Points to canvas currently in use (textureCanvas or screenCanvas).

	Global debug				:= False				'Prints out debug info on the screen
	Global drawWireframe		:= False				'Draws wireframes

	Global scale				:= 1.0					'How much the virtual resolution is scaled to fill the device
	Global rotation				:= 0.0					'To do: apply the transform matrix to the mouse, with rotation
	Global timeScale			:= 1.0					'Used by Shapes (like sprites) to slow down/speed up playback
	Global bgColor				:= [ 0.0, 0.0, 0.0 ]	'Background RGB values

	'************  Read only fields  **********************************************************************

	Function delta:Float()			; Return _delta;		End
	Function framerate:Float()		; Return _framerate;	End
	Function aspectRatio:Float()	; Return _aspectRatio;	End
	Function mouseX:Int()			; Return _mouseX;		End
	Function mouseY:Int()			; Return _mouseY;		End
	Function cropTop:Int()			; Return _cropTop;		End
	Function cropLeft:Int()			; Return _cropLeft;		End
	Function cropRight:Int()		; Return _cropRight;	End
	Function cropBottom:Int()		; Return _cropBottom;	End
	Function cropWidth:Int()		; Return _cropWidth;	End
	Function cropHeight:Int()		; Return _cropHeight;	End

	
	'************  Private variables  **********************************************************************

	Private

	Global _delta				:= 1.0					'delta time (relative to a 60fps target frame rate)
	Global _framerate 			:= 60					'desired effective frame rate
	Global _aspectRatio			:= 1.778				'Letterbox aspect ratio
	Global _mouseX				:Int					'Mouse X offset by camera
	Global _mouseY				:Int					'Mouse Y offset by camera
	Global _parallax			:Float					'Current layer's parallax
	
	Global _cropTop				:Int					'Cropped (after aspect ratio enforcement) dimensions
	Global _cropLeft			:Int
	Global _cropRight			:Int
	Global _cropBottom			:Int
	Global _cropWidth			:Int
	Global _cropHeight			:Int

	Global screenCanvas			:Canvas 				'Default canvas
	Global textureCanvas		:Canvas 				'Canvas used to render to a texture
	Global texture				:Image					'Image used by textureCanvas

	Global powWidth				:Int 					'texture width and height rounded to nearest power of two
	Global powHeight			:Int

	Global centerOffset			:= New Vector			'This provides a coordinate sytem where 0,0 is centered at the screen
	Global hud 					:= New StringStack		'Any string in this stack will be written on the screen
		

	'************  Public functions  **********************************************************************

	Public	

	Function SetResolution:Void( x:int, y:int, filter:Bool=True )
		'Use x=0 and y=0 to acquire the device's resolution
		
		If ( x <= 0 )
			width = DeviceWidth
		Else
			width = x
		End
		
		If ( y <= 0 )
			height = DeviceHeight
		Else
			height = y
		End
		
		camera.Size( width, height )

		filterTextures = filter
		
		screenCanvas = New Canvas

		powWidth = NearestPow( width )
		powHeight = NearestPow( height )

		texture = New Image( powWidth, powHeight, 0.5, 0.5, filterTextures )

		textureCanvas = New Canvas( texture )
		textureCanvas.SetProjection2d( 0, powWidth, 0, powHeight )
		textureCanvas.SetViewport( 0, 0, powWidth, powHeight )
		textureCanvas.SetScissor( (powWidth-width)/2, (powHeight-height)/2, width, height )
	End


	Function SetFrameRate:Void( fps:Int )
		_framerate = fps
		_delta = 60.0 / _framerate
		SetUpdateRate( _framerate )
	End
	
	
	Function GetMouse:Void()
		'Updates the mouse coordinates with the camera offset (converts the mouse to world coordinates).
		'Automatically runs at the end of Startframe.
		'Seems like we could use centerOffset here, but in reality it doesn't work for renderToTexture that way.
		_mouseX = ( ( MouseX - ( DeviceWidth/2.0 ) ) /scale ) + camera.x
		_mouseY = ( ( MouseY - ( DeviceHeight/2.0 ) ) /scale ) + camera.y
	End
	
	
	Function StartFrame:Void()
	
		If renderToTexture
			canvas = textureCanvas 
			centerOffset.Set( ( powWidth/2.0 ), ( powHeight/2.0 ) )

			textureCanvas.SetProjection2d( 0, powWidth, 0, powHeight )
			textureCanvas.SetViewport( 0, 0, powWidth, powHeight )
			textureCanvas.SetScissor( 0, 0, powWidth, powHeight )
			textureCanvas.Clear()	
		Else
			canvas = screenCanvas
			centerOffset.Set( ( DeviceWidth/2.0 ), ( DeviceHeight/2.0 ) )
		End
		
		screenCanvas.SetProjection2d( 0, DeviceWidth, 0, DeviceHeight )
		screenCanvas.SetViewport( 0, 0, DeviceWidth, DeviceHeight )
		screenCanvas.SetScissor( 0, 0, DeviceWidth, DeviceHeight )
		screenCanvas.Clear()
		
		If integerScaling
			scale = Int( DeviceHeight/height )
			If scale < 1.0 Then scale = 1.0
		Else
			scale = DeviceHeight/height
		End
		
		If enforceAspectRatio Or renderToTexture
			_aspectRatio = Float( width )/height
		Else
			_aspectRatio = Float( DeviceWidth )/DeviceHeight
		End
		
		If enforceAspectRatio Or renderToTexture
			_cropWidth = width * scale
			_cropHeight = height * scale
			_cropLeft = ( DeviceWidth - _cropWidth )/2
			_cropRight = _cropLeft + _cropWidth
			_cropTop = ( DeviceHeight - _cropHeight )/2
			_cropBottom = _cropTop + _cropHeight
		Else
			_cropWidth = DeviceWidth
			_cropHeight = DeviceHeight
			_cropLeft = 0
			_cropRight = _cropWidth
			_cropTop = 0
			_cropBottom = _cropHeight
		End

		camera.Size( _cropWidth/scale, _cropHeight/scale )

		If renderToTexture
			screenCanvas.Clear( 0.2, 0.2, 0.2, 1.0 )
			screenCanvas.SetScissor( _cropLeft, _cropTop, _cropWidth, _cropHeight )
			textureCanvas.Clear( bgColor[0], bgColor[1], bgColor[2] )
		Else
			screenCanvas.SetScissor( _cropLeft, _cropTop, _cropWidth, _cropHeight )
			screenCanvas.Clear( bgColor[0], bgColor[1], bgColor[2] )
		End
		
		GetMouse()
		screenCanvas.SetColor( 1.0, 1.0, 1.0, 1.0 )
		textureCanvas.SetColor( 1.0, 1.0, 1.0, 1.0 )
		screenCanvas.SetFont( Null )
		textureCanvas.SetFont( Null )
	End


	Function StartLayer:Void( parallax:Float )
		' This should be called before each layer is drawn
		_parallax = parallax
		canvas.PushMatrix()
		If renderToTexture
			textureCanvas.TranslateRotateScale(	( -camera.x * _parallax ) + centerOffset.x,
												( -camera.y * _parallax ) + centerOffset.y,
												rotation, 1.0, 1.0 )
		Else
			screenCanvas.TranslateRotateScale(	( ( -camera.x * scale ) * _parallax ) + centerOffset.x,
												( ( -camera.y * scale ) * _parallax ) + centerOffset.y,
												rotation, scale, scale )
		End
	End

	Function FinishLayer:Void()
		'Draw Origin
  		If drawWireframe		
  			If _parallax = 1.0
  				canvas.SetColor( .4, .7, .8, 1.0 )
  			Else
  				canvas.SetColor( .4, .8, .6, 0.25 )
  			End
  			canvas.DrawLine( camera.x1/_parallax, 0, camera.x2/_parallax, 0 )
  			canvas.DrawLine( 0, camera.y1/_parallax, 0, camera.y2/_parallax )
  			canvas.SetColor(1.0 ,1.0 ,1.0 )
  		End
		canvas.PopMatrix()
	End
	
	
	Function FinishFrame:Void()

		If renderToTexture
			textureCanvas.Flush()
			screenCanvas.DrawImage(	texture, screenCanvas.Width()/2.0, screenCanvas.Height()/2.0, 0, scale, scale )
		End
		
		screenCanvas.SetBlendMode( BlendMode.Alpha )
		screenCanvas.SetColor( 1.0, 1.0, 1.0, 1.0 )
		screenCanvas.SetScissor( 0, 0, DeviceWidth(), DeviceHeight() )
		
		Local y := 2
		For Local t := Eachin hud
			screenCanvas.DrawText( t, 5, y )
			y += 13
		Next
		hud.Clear()

		screenCanvas.Flush()
	End

	
	Function Print:Void(text:String, trim:Int=0)
		If debug
			If trim > 0
				Render.hud.Push(text[..trim])
			Else
				Render.hud.Push(text)
			End
		End
	End
	
End


'******************** Useful functions ***********************


Function NearestPow:Int( number:Int )
	Return Pow( 2, Ceil( Log( number )/Log( 2 ) ) );
End


