
Import mojo2
Import vector

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

	' Global fxMaterial			:Material				'If present, renders image with this material's shader '

	Global fxOverlay			:Image					'If present, overlays this image in multiply mode (useful for scanlines)
	Global fxOverlayScale		:= 8.0					'How many overlay pixels per render texture pixel
	Global drawOverlay			:= False

	Global glow 				:= False
	Global glowIntensity		:= 0.1
	Global glowSize				:= 0.5

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

	Global fxCanvas:Canvas
	Global fxImage:Image

	Global overlayCanvas:Canvas
	Global overlayImage:Image

	'************  Read only fields  **********************************************************************

	Public
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

		'******************************** shader stuff **********************************'

		' fxMaterial= New Material( CrtShader.Instance() )
		fxImage = New Image( width*8, height*8, 0.5, 0.5 )
		fxCanvas = New Canvas

		' Local overlayWidth := NearestPow( _cropWidth )
		' Local overlayHeight := NearestPow( _cropHeight )

		Local overlayWidth := ( width * 4 )
		Local overlayHeight := ( height * 4 )

		overlayImage = New Image( overlayWidth, overlayHeight, 0.5, 0.5, Image.Filter )
		overlayCanvas = New Canvas( overlayImage )
		overlayCanvas.SetProjection2d( 0, overlayWidth, 0, overlayHeight )
		overlayCanvas.SetViewport( 0, 0, overlayWidth, overlayHeight)
	End


	Function SetFrameRate:Void( fps:Int )
		_framerate = fps
		_delta = 60.0 / _framerate
		SetUpdateRate( _framerate )
	End


	Function SetOverlay( img:Image, overlaySize:Float )
		fxOverlay = img
		fxOverlayScale = overlaySize
		drawOverlay = True
	End


	Function SetGlow( intensity:Float, size:Float )
		glow = True
		glowIntensity = intensity
		glowSize = size
	End


	Function GetMouse:Void()
		'Updates the mouse coordinates with the camera offset (converts the mouse to world coordinates).
		'Automatically runs at the end of Startframe.
		'Seems like we could use centerOffset here, but in reality it doesn't work for renderToTexture that way.
		_mouseX = ( ( MouseX - ( DeviceWidth/2.0 ) ) /scale ) + camera.x
		_mouseY = ( ( MouseY - ( DeviceHeight/2.0 ) ) /scale ) + camera.y
	End


	Function StartFrame:Void()

		' If drawOverlay And overlayImage = Null
		'
		' End

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
			screenCanvas.Clear()
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
			' If fxMaterial
				' DrawWithMaterial( texture, fxImage )
			' Else
				screenCanvas.DrawImage(	texture, screenCanvas.Width()/2.0, screenCanvas.Height()/2.0, 0, scale, scale )
			' End
		End

		' Draws tiled overlay image (scanlines)
		If fxOverlay And drawOverlay
			screenCanvas.SetBlendMode( BlendMode.Multiply2 )
			screenCanvas.SetColor( 1.0, 1.0, 1.0, 1.0 )
			fxOverlay.SetHandle( 0, 0 )
			Local fxScale := scale / fxOverlayScale
			Local fxWidth := fxOverlay.Width * fxScale
			Local fxHeight := fxOverlay.Height * fxScale
			local x := _cropLeft
			While ( x < _cropRight )
				local y := _cropTop
				While ( y < _cropBottom )
					screenCanvas.DrawImage(	fxOverlay, x, y, 0, fxScale, fxScale )
					y += fxHeight
				End
				x += fxWidth
			End
		End

		If glow And renderToTexture
			overlayCanvas.Clear()
			DrawGlowSteps( 1, 0 )
			DrawGlowSteps( -1, 0 )
			DrawGlowSteps( 0, 1 )
			DrawGlowSteps( 0, -1 )
			overlayCanvas.Flush()
			screenCanvas.SetBlendMode( BlendMode.Additive )
			screenCanvas.SetColor( 1.0, 1.0, 1.0, glowIntensity )
			screenCanvas.DrawImage(	overlayImage, screenCanvas.Width()/2.0, screenCanvas.Height()/2.0, 0, scale, scale )
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


	Function Echo:Void(text:String, ignoreDebug:Bool = False, trim:Int=0)
		If debug Or ignoreDebug
			If trim > 0
				Render.hud.Push(text[..trim])
			Else
				Render.hud.Push(text)
			End
		End
	End


	' Function DrawWithMaterial:Void(img:Image, targetCanvas:Canvas )
	' 	fxMaterial.SetTexture("ColorTexture", img.Material.ColorTexture)
	' 	targetCanvas.DrawRect( _cropLeft, _cropTop, _cropWidth, _cropHeight, fxMaterial )
	' End
	'
	'
	' Function DrawWithMaterial:Void(img:Image, targetImg:Image )
	' 	fxMaterial.SetTexture("ColorTexture", img.Material.ColorTexture)
	' 	fxCanvas.SetRenderTarget( targetImg )
	' 	fxCanvas.SetViewport(0, 0, targetImg.Width, targetImg.Height)
	' 	fxCanvas.SetProjection2d(0, targetImg.Width, 0, targetImg.Height)
	' 	fxCanvas.Clear()
	' 	fxCanvas.DrawRect ( 0,0,targetImg.Width,targetImg.Height,fxMaterial )
	' 	fxCanvas.Flush()
	' 	screenCanvas.DrawImage(	targetImg, screenCanvas.Width()/2.0, screenCanvas.Height()/2.0, 0, 1.0, 1.0 )
	' End


	Function DrawGlowSteps( xAmount:Float, yAmount:Float )
		Local x := 0.0
		Local y := 0.0
		local glowOffset := glowSize
		local glowStep := glowOffset / 4
		Local alpha := 1.0
		local alphaStep := 0.25
		While ( Abs(x) < Abs(glowOffset) ) And ( Abs(y) < Abs(glowOffset) )
			overlayCanvas.SetBlendMode( BlendMode.Additive )
			overlayCanvas.SetColor( 1.0, 1.0, 1.0, alpha )
			overlayCanvas.DrawImage( texture, overlayImage.Width/2.0 + x, overlayImage.Height/2.0 + y, 0, 1, 1 )
			x += glowStep * xAmount
			y += glowStep * yAmount
			alpha -= alphaStep
		End
	End



End


'******************** Useful functions ***********************


Function NearestPow:Int( number:Int )
	Return Pow( 2, Ceil( Log( number )/Log( 2 ) ) );
End





'******************** Shaders  ***********************

' Class CrtShader Extends Shader
'
' 	Global _instance:CrtShader
'
' 	Field aspectRatio := 1.0
' 	Field distortion := 0.5
' 	Field border := 1.25
'
' 	Method New()
' 		Build( LoadString( "monkey://data/crt.glsl" ) )
' 	End
'
' 	'must implement this - sets valid/default material params
' 	Method OnInitMaterial:Void( material:Material )
' 		material.SetTexture("ColorTexture", Texture.White())
' 		material.SetScalar("AspectRatio", aspectRatio )
' 		material.SetScalar("EffectLevel", distortion )
' 		material.SetScalar("BorderLevel", border )
' 	End
'
' 	Function Instance:CrtShader()
' 		If Not _instance Then _instance = New CrtShader
' 		Return _instance
' 	End
'
' End

' Class GlowShader Extends Shader
'
' 	Global _instance:GlowShader
'
' 	Method New()
' 		Build( LoadString( "monkey://data/glow.glsl" ) )
' 	End
'
' 	'must implement this - sets valid/default material params
' 	Method OnInitMaterial:Void( material:Material )
' 		material.SetTexture("ColorTexture", Texture.White())
' 	End
'
' 	Function Instance:GlowShader()
' 		If Not _instance Then _instance = New GlowShader
' 		Return _instance
' 	End
'
' End
