	

		// background
		itemDef 
		{
			rect			80 30 480 420
			style			WINDOW_STYLE_FILLED
			border			1
			bordercolor		0.20 0.50 0.90 0.40
			forecolor		1 1 1 1
			backcolor		0.02 0.05 0.10 0.88
			visible			1
			decoration
		}


		// header — original uidr_header shader (keeps the image)
		itemDef 
		{
			rect			80 30 480 60
			style			WINDOW_STYLE_SHADER
			background		"uidr_header"
			visible			1
			decoration
		}

		// header — dark navy overlay to bring it into the blue/dark scheme
		itemDef
		{
			rect			80 30 480 60
			style			WINDOW_STYLE_FILLED
			backcolor		0.02 0.06 0.18 0.72
			visible			1
			decoration
		}

		// player name (top-right of header)
		itemDef
		{
			visible			1
			origin			510 68
			forecolor		0.85 0.95 1.0 1.0
			exp				text( dvarString( "name" ) )
			textfont		UI_FONT_NORMAL
			textalign		ITEM_ALIGN_RIGHT
			textscale		0.4
			decoration
		}

		// menu name ("Welcome") — blue-white accent to match buttons
		itemDef
		{
			visible			1
			origin			90 80
			forecolor		0.75 0.90 1.0 1.0
			exp				text( dvarString( "menuName" ) )
			textfont		UI_FONT_NORMAL
			textalign		ITEM_ALIGN_LEFT
			textscale		0.8
			textstyle		ITEM_TEXTSTYLE_SHADOWED
			decoration
		}

		// rank icon
		itemDef 
		{
			rect			518 37 32 32
			style			WINDOW_STYLE_SHADER
			exp				material( tablelookup( "mp/rankIconTable.csv", 0, stat(252), stat(2326)+1 ) )
			visible			1
			decoration
		}

		// rank name
		itemDef
		{
			visible			1
			origin			550 82
			forecolor		0.70 0.85 1.0 0.85
			exp				text( "@"+tablelookup("mp/ranktable.csv",0,stat(252)+1,5) )
			textfont		UI_FONT_NORMAL
			textalign		ITEM_ALIGN_RIGHT
			textscale		0.32
			decoration
		}

		// version text — centered in the footer strip (y=445, full panel width x=80–560)
		itemDef
		{
			visible			1
			rect			80 440 480 10
			forecolor		0.35 0.55 0.80 0.70
			text			"Death Run Mod 1.2 by BraXi"
			textfont		UI_FONT_NORMAL
			textalign		ITEM_ALIGN_CENTER
			textaligny		8
			textscale		0.28
			textstyle		ITEM_TEXTSTYLE_SHADOWED
			decoration
		}

		// easter egg button (invisible, keep intact)
		itemDef
		{
			style			WINDOW_STYLE_FILLED 
			forecolor		1 1 1 0.8 
			rect			540 435 10 10

			type			ITEM_TYPE_BUTTON
			exp				text( " " ) 
			textfont		UI_FONT_NORMAL
			textstyle		ITEM_TEXTSTYLE_SHADOWED 
			textalign		ITEM_ALIGN_LEFT
			textscale		0.32
			textalignx		70
			textaligny		22
			visible			when( !dvarInt( "dr_ee1" ) )
			action 
			{ 
				play "ee1"; 
				execNow "set dr_ee1 1";
			} 
		} 

//+"  -"+"U "+"M"+"A"+"D"+"?"

