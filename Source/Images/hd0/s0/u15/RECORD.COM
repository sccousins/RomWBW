�Z3ENV �*	�U�D|��J�,�[
Abort -- I/O Driver Address NOT Defined �� ʅ��ҳ�,�[
Abort -- Disk Driver Module NOT Loaded ��,�[
Abort -- No I/O Driver Module Loaded �:] �O�e:^ �N�:m �P���,�[  ++ TTY Recording ON ++ ���,�[  ++ CRT Recording ON ++ ��:m �P�?�$�,�[  ++ TTY Recording OFF ++
 ���,�[  ++ CRT Recording OFF ++
 ��,�[

RECORD turns on and off recording of screen displays
on disk under ZCPR3 with the SYSIO Redirectable I/O Drivers
engaged.

It is invoked by two forms:

	RECORD ON  or RECORD ON PRINTER
	RECORD OFF or RECORD OFF PRINTER

Minimum Required Option Forms are ON, OF, and P:
	RECORD ON P = RECORD ON PRINTER
If the P option is given, then TTY output is recorded,
else CRT output is recorded.
 ���  �D�����$ ���' ���* ���- ��[RECORD, Version 3.0 ��*Y ^#V#~�ѷ�"Y�@���a����� ~#�ʵ�	ʟ͹�ʌ�
ʑ�ʑ�ʕ�f �f�fy��f�fy�G>�G�O> ͹«�f��������O* .��������#V#~�ѷ�"Y�@���a����� ~#�ʵ�	ʟ͹�ʌ�
ʑ�