� Z3ENV            �                P�� PB:          SH      VAR                                              �MKZCM, NZCOM, NZ-COM, (New) Z-Com are Copyright 1987, 1988 by Joe Wright and Alpha Systems Corp.                               
001-10147 �s�1�!��* .">�2.Z��  #�>�2�*	"� � ��:2��*. :��n��"&0�"+")��"	��"$��"":�n"  �S: �(�*!& �\��n"  �S:�(�! �\��n"  �S:�(�n"  �S:�(�n"  �S:�2�(�n":��n. "E:D�n"B:A�n"?!] ~�/(�? 6 ���U͸
1.	Command Processor	CPR	 *?:A�"͸2.	Disk Operating System	DOS	 *B:D�"͸3.	NZ-COM Bios		BIO	 *E�#�"͸
4.	In/Output Processor	IOP	 *:�"͸5.	Resident Command Proc	RCP	 *:�"͸6.	Flow Control Processor	FCP	 *:�"͸7.	Named Directory Reg	NDR	 *:�?͸ Names
8.	Shell Stack		SHS	 *: �?͸ x  :!�͸ Bytes

9.*	Environment Descriptor	ENV	 *:�"͸
U.	User's Memory Area	UMA	 *$��*. ��R|��2�� !  �"͸	Customer's CBIOS	TOP	 *. ͜͸

		Effective TPA size *B%�<��<�|ͯ>.�o}} !  =�T��O͸k

* Item 9 is not changeable in this version.

 ���^�ʕ��Qʕ�Xʕ�H���/���?���S��1��	�2�
�3�j
�4��5�Z�6ʓ�7���8ʦ
�U�6
>�o�:�����͸Selection: (or <S>ave, <Q>uit or <H>elp)  ��*�F*�F*�F*�F*�F*�|���R�|2����͸

MKZCM Version 1.0 System Generator for Z-Com v2.0
Copyright (C) 1987-88 Alpha Systems      !;͸
 ��U͸
Syntax:  MKZCM [name]

MKZCM will display the current system configuration and addresses and 
prompt you to change something, save this configuration, or quit.  You may 
select changes to the size of certain of the system segments.  As changes 
are made, the system is re-calculated and re-displayed to reflect your last 
change and prompt you for more changes or to save this configuration in 
name.ZCM and name.ENV or quit.

This version allows you to change the sizes of CPR, DOS and BIO segments as 
well as the configuration of the Shell Stack.

You may specify the output file name when you invoke MKZCM.  If you do not, 
the Save function will prompt you for the file name.

            Press any key to return to MKZCM or ^C to Quit now.



 �^�ʕ�,��͸ CPR size? (Now  :A�͸)  ͯ��2A�O��͸ DOS size? (Now  :D�͸)  ͯ��2D�O͸ User's area size? (Now  :��͸)  ͯ��2��O��͸ Bios size? (Now  :��͸)  ͯ��>�0{<��2�2��O͸ Entries? (Now  : �͸)  ͯ���(H2 ��͸ Shell Size? (Now  :!�͸)   ͯ���(2!�* & �\��Q2 �O!  " �O͸ How many IOP records? (Now  :�͸)  ͯ��22��O͸ How many RCP records? (Now  :�͸)  ͯ��!s�O͸ How many FCP records? (Now  :�͸)  ͯ��!s�O͸ How many names? (Now  :�͸)  ͯ��! �s >��o��>�<8�2�O> 2] ��:] � �W�͸ Output Filename? (^C to Quit)  ͯ�(�\ ��] �/ �/(��?(�(�!����͸ Making  ] �ͦ!�"�! #͆>�L́�~�~�~�~�~�~�~�~́͆͆͆́͆́́́́́́́́́͆́́́́́́́́́�~�~͆>7�L́́Ͱe !� ��͸, Making  \ ����5�|<�}! ��͚�}͊<��}!] ~#� (���>.��!e Þ͆��ͷ���͕��~#�����~#����\ �%��}�A��}z��{��> ������0�:8��3��}�*�͕"�!�5 6������>	�>��>
�^#V#�^# ��(> �o�>�o��?͸ Record �=>s�o͸
 ��͜͸	 �ï�o�$�/<_���<��s >��o�|������!  ��=�:��(*�."~#fo6###>�w�{��    ENVZCMNZ-COM�CBIOS ENVTYP EXPATH EXPATHS RCP RCPS IOP IOPS FCP FCPS Z3NDIR Z3NDIRS Z3CL Z3CLS Z3ENV Z3ENVS SHSTK SHSTKS SHSIZE Z3MSG EXTFCB EXTSTK QUIET Z3WHL SPEED MAXDRV MAXUSR DUOK CRT PRT COLS ROWS LINS DRVEC SPAR1 PCOL PROW PLIN FORM SPAR2 SPAR3 SPAR4 SPAR5 CCP CCPS DOS DOSS BIO PUBDRV PUBUSR ������ ������>�2�2�$կ����~#�:��,�`�!�`���~��A��A�����<2�#~�:�a�?�62�#~�:�a��G~#�:�T�0��
�Ox�����G�8x� �2��a�~�:�h#~�,�s�!ҋ>?�x:�G:�O�>���ͥ~�.#ͥ�~���~�����*·>?ù#¥���#ý> ���  ~����!���=��_��.��:��;��,��<��>ɾ��  ~�0��0�
���bk)))���_z� W#��{���!H��!��G�!H�j�!�ï�!H���!���                                                                                                                                                                                                                                                                                                                                                >ø>ø>ø>ø>ø>ø>����*2�!( �� *2####�� �� � ��*2�!( �� *2####�� �� � ����~�¶"2####�$�;��5�J�¢ͽ§*26�#6�#�!& �s#r�ø��~�¶"2####�$�;��5�b��1ì��~�ʘ"2##^#Vz�ʧ24r+s+5§6�#�!& �s#rͽʧ*2##6 #6 ���:4���24~�ʘ"2##^#V:4r+s+5§6�#�!& �s#r��ʧÝ��~�ʸ"2���~�ʸ"2#~���>�+~�����+�*26 ####�� ��ʱ�ø�*2ï   �����w ͋��������̓���]>���^��������̓���]̓���]�Wͥ��̓������̓��ʗ������̓������̓����~�                                                                                                                                                                                                           ��2}�
� !�~#�o|� g6 :}�ʯ!�~�ʯ�w#â��!�:���;����� ~#���	���1����
���������� ����y�����y�G>�G�O> �o����������d�.
�.�0�o���� ��8�0�_y��E��E{� y�0�o{�����'�x��xd �x
 �x}�0�o����� }�o|�gڇ�z}�o|�gy��� y�0�o�|��}������� ô���d��
���0�o���� ������_y������> �o{� y�0�o{������������
��7�o�0�o����#>.�o�#������ �o�#�� �o� �o��o��o�
�o��o��>^�o��@�o�����* .	k����������O* .~���������� ����H ͔������W͵������H ͪ�����W͵����r#x�µ����H 	�	������	�	����H ��������|�����}���~#x��������	�	�~+x������a��{��_�                                                                                                    