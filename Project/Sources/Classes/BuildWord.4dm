/*
BuildWord ("Construis le mot") — a picture, empty slots, and shuffled syllable tiles;
the child taps the syllables in order to spell the word. Animated by Hero (cs.hero).

Tapping the next correct syllable flies it into the next slot; a wrong tile shakes.
Complete the word to win and move on.

Store the instance in Form.game.

(4D evaluates left-to-right with NO operator precedence, so arithmetic inside a comparison
or an index is parenthesised.)
*/

property transition : cs.hero.ElementTransition
property palette : Collection:=[0x00E8B84B; 0x005B9BD5; 0x006FB98F; 0x00E0736A; 0x009B8BC4]
property colorIdx : Integer:=0

property words : Collection:=[\
{emoji: "🏍️"; word: "moto"; syls: ["mo"; "to"]}; \
{emoji: "🐴"; word: "cheval"; syls: ["che"; "val"]}; \
{emoji: "🐰"; word: "lapin"; syls: ["la"; "pin"]}; \
{emoji: "🐢"; word: "tortue"; syls: ["tor"; "tue"]}; \
{emoji: "🦁"; word: "lion"; syls: ["li"; "on"]}; \
{emoji: "🏠"; word: "maison"; syls: ["mai"; "son"]}; \
{emoji: "🌞"; word: "soleil"; syls: ["so"; "leil"]}; \
{emoji: "🐷"; word: "cochon"; syls: ["co"; "chon"]}; \
{emoji: "🐮"; word: "vache"; syls: ["va"; "che"]}; \
{emoji: "🦆"; word: "canard"; syls: ["ca"; "nard"]}; \
{emoji: "🍎"; word: "pomme"; syls: ["pom"; "me"]}; \
{emoji: "🦋"; word: "papillon"; syls: ["pa"; "pi"; "llon"]}; \
{emoji: "🍫"; word: "chocolat"; syls: ["cho"; "co"; "lat"]}; \
{emoji: "🍌"; word: "banane"; syls: ["ba"; "na"; "ne"]}; \
{emoji: "🚗"; word: "voiture"; syls: ["voi"; "tu"; "re"]}; \
{emoji: "🦒"; word: "girafe"; syls: ["gi"; "ra"; "fe"]}; \
{emoji: "🍅"; word: "tomate"; syls: ["to"; "ma"; "te"]}; \
{emoji: "🐌"; word: "escargot"; syls: ["es"; "car"; "got"]}]

property slotsMax : Integer:=4
property level : Text:="easy"               // easy = 2 syllables, normal = up to 4
property syls : Collection                   // the word's ordered syllables
property order : Collection                  // the shuffled tile syllables
property used : Collection                   // [i] tile consumed
property placed : Integer                    // how many syllables placed
property score : Integer:=0
property busy : Boolean:=False
property sound : Boolean:=True

Class constructor($transition : cs.hero.ElementTransition)

	This.transition:=$transition
	OBJECT SET VISIBLE(*; "glyph"; False)
	This._highlightLevel(1)
	This.newQuestion()

	// === === === === === === === === === === === === === === === === === === === ===
Function selectLevel($i : Integer)

	If ($i=1)
		This.level:="easy"
	Else
		This.level:="normal"
	End if
	This._highlightLevel($i)
	This.newQuestion()

	// === === === === === === === === === === === === === === === === === === === ===
Function toggleSound()

	This.sound:=Not(This.sound)
	If (This.sound)
		OBJECT SET TITLE(*; "speaker"; "🔊")
	Else
		OBJECT SET TITLE(*; "speaker"; "🔇")
	End if

	// === === === === === === === === === === === === === === === === === === === ===
Function newQuestion()

	var $w : Object:=This._pickWord()
	This.syls:=$w.syls
	This.order:=This._shuffle($w.syls)
	This.placed:=0
	This.used:=[]
	var $k : Integer
	For ($k; 0; This.order.length-1)
		This.used.push(False)
	End for

	OBJECT SET TITLE(*; "emoji"; $w.emoji)
	This._renderSlots()
	This._renderTiles()

	OBJECT SET TITLE(*; "score"; String(This.score))
	OBJECT SET VISIBLE(*; "glyph"; False)

	This.colorIdx:=((This.colorIdx+1) % This.palette.length)
	This.transition.animate("card").to({backgroundColor: This.palette[This.colorIdx]}).duration(300).easing("easeInOutQuad").start()
	This._popIn("emoji")

	This.busy:=False

	// === === === === === === === === === === === === === === === === === === === ===
	// The player tapped tile $i.
Function tapTile($i : Integer)

	If (This.busy)
		return
	End if
	If (This.used[($i-1)])
		return
	End if

	var $syl : Text:=This.order[($i-1)]

	If ($syl=This.syls[This.placed])   // the next one — place it

		var $pos : Integer:=This.placed
		OBJECT SET TITLE(*; "slotLbl_"+String($pos+1); $syl)
		This.transition.animate("slotLbl_"+String($pos+1)).from({fontSize: 8}).to({fontSize: 28}).duration(260).easing("easeOutBack").start()
		OBJECT SET RGB COLORS(*; "slot_"+String($pos+1); 0x00D6F5E3; 0x00D6F5E3)

		This.used[($i-1)]:=True
		OBJECT SET VISIBLE(*; "tile_"+String($i); False)
		OBJECT SET VISIBLE(*; "tileLbl_"+String($i); False)
		OBJECT SET VISIBLE(*; "tileBtn_"+String($i); False)

		This.placed:=This.placed+1
		If (This.placed>=This.syls.length)   // word complete
			This.busy:=True
			This.score:=This.score+1
			OBJECT SET TITLE(*; "score"; String(This.score))
			This._bumpScore()
			This._showGlyph("✓")
			This.transition.animate("tick").to({left: 1}).delay(1200).then(Formula(Form.game._advance())).start()
		End if

	Else   // wrong tile

		This._shakeTile($i)
		If (This.sound)
			BEEP
		End if

	End if

Function _advance()

	OBJECT SET COORDINATES(*; "tick"; 0; -10; 1; -9)
	This.newQuestion()

	// === === === === === === === === === === === === === === === === === === === ===
Function _pickWord() : Object

	If (This.level="normal")
		return This.words[(Random % This.words.length)]
	End if
	var $pool : Collection:=[]
	var $w : Object
	For each ($w; This.words)
		If ($w.syls.length=2)
			$pool.push($w)
		End if
	End for each
	return $pool[(Random % $pool.length)]

	// empty slots, one per syllable, centred
Function _renderSlots()

	var $n : Integer:=This.syls.length
	var $cw : Integer:=62
	var $gap : Integer:=8
	var $total : Integer:=($n*$cw)+(($n-1)*$gap)
	var $startx : Integer:=190-($total\2)
	var $y : Integer:=(64+214)

	var $k : Integer
	For ($k; 1; This.slotsMax)
		var $pad : Text:="slot_"+String($k)
		var $lbl : Text:="slotLbl_"+String($k)
		If ($k<=$n)
			var $x : Integer:=$startx+(($k-1)*($cw+$gap))
			OBJECT SET COORDINATES(*; $pad; $x; $y; $x+$cw; $y+50)
			OBJECT SET COORDINATES(*; $lbl; $x; $y; $x+$cw; $y+50)
			OBJECT SET TITLE(*; $lbl; "")
			OBJECT SET RGB COLORS(*; $pad; 0x00FFFFFF; 0x00FFFFFF)
			OBJECT SET VISIBLE(*; $pad; True)
			OBJECT SET VISIBLE(*; $lbl; True)
		Else
			OBJECT SET VISIBLE(*; $pad; False)
			OBJECT SET VISIBLE(*; $lbl; False)
		End if
	End for

	// shuffled syllable tiles
Function _renderTiles()

	var $n : Integer:=This.order.length
	var $cw : Integer:=68
	var $gap : Integer:=10
	var $total : Integer:=($n*$cw)+(($n-1)*$gap)
	var $startx : Integer:=190-($total\2)
	var $y : Integer:=(64+320)

	var $k : Integer
	For ($k; 1; This.slotsMax)
		var $pad : Text:="tile_"+String($k)
		var $lbl : Text:="tileLbl_"+String($k)
		var $btn : Text:="tileBtn_"+String($k)
		If ($k<=$n)
			var $x : Integer:=$startx+(($k-1)*($cw+$gap))
			OBJECT SET COORDINATES(*; $pad; $x; $y; $x+$cw; $y+56)
			OBJECT SET COORDINATES(*; $lbl; $x; $y; $x+$cw; $y+56)
			OBJECT SET COORDINATES(*; $btn; $x; $y; $x+$cw; $y+56)
			OBJECT SET TITLE(*; $lbl; This.order[($k-1)])
			OBJECT SET VISIBLE(*; $pad; True)
			OBJECT SET VISIBLE(*; $lbl; True)
			OBJECT SET VISIBLE(*; $btn; True)
		Else
			OBJECT SET VISIBLE(*; $pad; False)
			OBJECT SET VISIBLE(*; $lbl; False)
			OBJECT SET VISIBLE(*; $btn; False)
		End if
	End for

	// === === === === === === === === === === === === === === === === === === === ===
Function _shakeTile($i : Integer)

	var $t:=cs.hero.ElementState.new("tile_"+String($i))
	This.transition.animate("tile_"+String($i)).from({left: $t.left-10}).to({left: $t.left}).duration(450).easing("easeOutElastic").start()
	This.transition.animate("tileLbl_"+String($i)).from({left: $t.left-10}).to({left: $t.left}).duration(450).easing("easeOutElastic").start()

Function _shuffle($c : Collection) : Collection

	var $src : Collection:=$c.copy()
	var $out : Collection:=[]
	While ($src.length>0)
		var $k : Integer:=(Random % $src.length)
		$out.push($src[$k])
		$src.remove($k)
	End while
	return $out

Function _popIn($name : Text)

	var $s:=cs.hero.ElementState.new($name)
	var $cx : Integer:=$s.left+($s.width\2)
	var $cy : Integer:=$s.top+($s.height\2)
	OBJECT SET COORDINATES(*; $name; $cx; $cy; $cx; $cy)
	This.transition.animate($name).to({left: $s.left; top: $s.top; width: $s.width; height: $s.height}).duration(280).easing("easeOutBack").start()

Function _showGlyph($char : Text)

	OBJECT SET TITLE(*; "glyph"; $char)
	var $g:=cs.hero.ElementState.new("glyph")
	var $cx : Integer:=$g.left+($g.width\2)
	var $cy : Integer:=$g.top+($g.height\2)
	OBJECT SET COORDINATES(*; "glyph"; $cx; $cy; $cx; $cy)
	OBJECT SET VISIBLE(*; "glyph"; True)
	This.transition.animate("glyph").to({left: $g.left; top: $g.top; width: $g.width; height: $g.height}).duration(240).easing("easeOutBack").start()

Function _bumpScore()

	This.transition.animate("score").to({fontSize: 40}).duration(130).easing("easeOutQuad").then(Formula(Form.game._scoreBack())).start()

Function _scoreBack()

	This.transition.animate("score").to({fontSize: 28}).duration(180).easing("easeInOutCubic").start()

Function _highlightLevel($sel : Integer)

	var $i : Integer
	For ($i; 1; 2)
		If ($i=$sel)
			OBJECT SET RGB COLORS(*; "lvlPad_"+String($i); 0x00344054; 0x00344054)
			OBJECT SET RGB COLORS(*; "lvlLbl_"+String($i); 0x00FFFFFF; 0x00344054)
		Else
			OBJECT SET RGB COLORS(*; "lvlPad_"+String($i); 0x00E4E7EC; 0x00E4E7EC)
			OBJECT SET RGB COLORS(*; "lvlLbl_"+String($i); 0x00667085; 0x00E4E7EC)
		End if
	End for
