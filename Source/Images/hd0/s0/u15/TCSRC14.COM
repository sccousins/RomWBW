�Z3ENV  �sn1n!���KTCSRC vers 1.4
Creates a commented source code [.Z80] file
from the ZCPR3 environment or from a Z3TCAP[.Z3T] file.
 !] >/�#��K
Syntax:	TCSRC [[dir:]infile[.Z3T]] [[dir:]outfile[.z80]]

	Default outfile name is infile.Z80.
	Infile 'BLANK' creates blank commented source code.
	If no infile is specified, Z3TCAP.Z80 is created 
		from the environment.
 ɯ!���Ye �  !a ��:] �  !Y]  ��!l �� ���� ��x<2�2��  !]  ����  !d ��!] Q�; !�> �Y�!�>�w�!] Y�; *	� "�Y\ �u�	 "�K
File  ] ���K Not Found
 ��% ��-(���K
File Read Error
 �!� "�ͅ"�*�1 ��#�͸A
͸�!&�[���!���>.!���!:��͛ͩ͹ͩ͹͛>���Y���u�	(;͎�(1�K
Existing File  ������K is Read/Only
 �� ��� �K
File Create Error
 �*�� � ����2 4�!� � >��� ���K
File  ������K Created
 ��K
File Write Error
 ��{n�~#����0��� ~� #ɯ2�~#� :���� 8/�(�:��ą��>H͈��:�� ͓>�2���� :��ą��!k ����>�O��:��ą��o͈� ~#� >0�� 8��͍�����!o ����>�O��@͍��!g ����>�O�͓�>,	͓�>'������C���������~#����������������!s ���>�O��������>����G> ���~#���~#� ���:��@�0:��/�
8�
0��
Ox�0y�0�0>:�0�;
; Z3TCAP file:   
;
ESC	EQU	27		; Escape character
;
; The first character in the terminal name must not be a space.  For
; Z3TCAP.TCP library purposes only, the name terminates with a space
; and must be unique in the first eight characters.
;
TNAME:	DB	'             '	; Name of terminal (13 chars)
;
GOFF:	DB	GOELD-TNAME	; Graphics offset from Z3TCAP start
;
; Terminal configuration bytes B14 and B15 are defined and bits assigned
; as follows.  The remaining bits are not currently assigned.  Set these
; bits according to your terminal configuration.
;
;	B14 b7: Z3TCAP Type.... 0 = Standard TCAP  1 = Extended TCAP
;
;	bit:	76543210
B14:	DB	00000000B	; Configuration byte B14
;
;	B15 b0: Standout....... 0 = Half-Intensity 1 = Reverse Video
;	B15 b1: Power Up Delay. 0 = None           1 = Ten-second delay
;	B15 b2: No Auto Wrap... 0 = Auto Wrap      1 = No Auto Wrap
;	B15 b3: No Auto Scroll. 0 = Auto Scroll    1 = No Auto Scroll
;	B15 b4: ANSI........... 0 = ASCII          1 = ANSI
;
;	bit:	76543210
B15:	DB	00000000B	; Configuration byte B15
;
; Single character arrow keys or WordStar diamond
;
	DB	 		; Cursor up
	DB	 		; Cursor down
	DB	 		; Cursor right
	DB	 		; Cursor left
;
; Delays (in ms) after sending terminal control strings
;
	DB	 		; CL delay
	DB	 		; CM delay
	DB	 		; CE delay
;
; Strings start here
;
CL:	DB	 ; Home cursor and clear screen
CM:	DB	 ; Cursor motion macro
CE:	DB	 ; Erase from cursor to end-of-line
SO:	DB	 ; Start standout mode
SE:	DB	 ; End standout mode
TI:	DB	 ; Terminal initialization
TE:	DB	 ; Terminal deinitialization
;
; Extensions to standard Z3TCAP
;
LD:	DB	 ; Delete line at cursor position
LI:	DB	 ; Insert line at cursor position
CD:	DB	 ; Erase from cursor to end-of-screen
;
; The attribute string contains the four command characters to set
; the following four attributes for this terminal in the following
; order:  	Normal, Blink, Reverse, Underscore
;
SA:	DB	 ; Set screen attributes macro
AT:	DB	 ; Attribute string
RC:	DB	 ; Read current cursor position
RL:	DB	 ; Read line until cursor
;
; Graphics TCAP area
;
GOELD:	DB	 		; Graphics On/Off delay in ms
;
; Graphics strings
;
GO:	DB	 ; Graphics mode On
GE:	DB	 ; Graphics mode Off
CDO:	DB	 ; Cursor Off
CDE:	DB	 ; Cursor On
;
; Graphics characters
;
GULC:	DB	 		; Upper left corner
GURC:	DB	 		; Upper right corner
GLLC:	DB	 		; Lower left corner
GLRC:	DB	 		; Lower right corner
GHL:	DB	 		; Horizontal line
GVL:	DB	 		; Vertical line
GFB:	DB	 		; Full block
GHB:	DB	 		; Hashed block
GUI:	DB	 		; Upper intersect
GLI:	DB	 		; Lower intersect
GIS:	DB	 		; Mid intersect
GRTI:	DB	 		; Right intersect
GLTI:	DB	 		; Left intersect
;
;  Fill remaining space with zeros
;
	 REPT	128-($-TNAME)
	DB	0
	 ENDM

	END
;
; End of Z3TCAP
;

 BLANK   Z3TCAP  Z3TZ80-40HESC,+80H0 ������(G! N������������?(��(3��7>͕�<(&=�����O !� 	 ��~���O~怱����O�y����������Y ͌X͌��������͌�� ͌O�G����>͕<�� >͕���>�'>�'>͕���>Õ>Õ���� rr# �������Q���� ~#� ����	(͡�(��
(	�(� ��S�y/�<G> �0����� �ѷ����O� �����Ͷ�0��>^�0��@�0����� 0�����	8�
ɿ������>.�0�������� �0������&d�&
������.��,0��g}� �|�> (��0G|���x���|�����O>�f����H �D������� �G(+�?������_���w#������n����o��* o���Ɛ'�@'���*�� j���p                                                                                                            