// Construis le mot — driven by cs.hero.

Case of

		//______________________________________________________
	: (Form event code=On Load)

		Form.transition:=cs.hero.ElementTransition.new()
		Form.game:=cs.BuildWord.new(Form.transition)

		//______________________________________________________
	: (Form event code=On Timer)

		Form.transition.onTimer()

		//______________________________________________________
	: (Form event code=On Clicked)

		var $name : Text:=FORM Event.objectName

		Case of
			: (Position("tileBtn_"; $name)=1)
				Form.game.tapTile(Num(Substring($name; 9)))
			: (Position("lvlBtn_"; $name)=1)
				Form.game.selectLevel(Num(Substring($name; 8)))
			: ($name="btnSpeaker")
				Form.game.toggleSound()
		End case

		//______________________________________________________
	: (Form event code=On Unload)

		SET TIMER(0)

		//______________________________________________________
End case
