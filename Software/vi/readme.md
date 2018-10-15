Tandy 2000 Compatible vi

---

Notes from aquishix here... the original VI_CMP.EXE has been included in case it is needed.  I hex-edited the original VI_CMP.EXE and replaced the string "VI_CMP.EXE" within it as "C:\VI\VI.EXE", saving it as VI.EXE.  Since the new string is two characters longer than the original, I deleted two of the '$' padding characters immediately following the null character 0x00.  This amazingly worked and prevented the program from failing upon not finding the file VI_CMP.EXE in its PWD.

However, if you place the VI.EXE file anywhere else, you will have to modify the binary executable yourself to accomodate the change, or figure out another solution.  One such solution that I came up with, which also works, is this:

* Use the original VI_CMP.EXE
* Place the VI_CMP.EXE file wherever you feel like
* Construct a batch file roughly equivalent to the following:

---
copy (wherever)\VI_CMP.EXE
VI_CMP.EXE %1 %2 %3 %4 %5 %6 %7 %8 %9
del VI_CMP.EXE
---

I have already done this for you and saved the batch file as VIM.BAT.  If you want to rename it as VI.BAT, you will need to delete or rename the VI.EXE file because MS-DOS puts .BAT files before .EXE in the executable extension priority list.

-

You will need to include

DEVICE=ANSI.SYS

(FROM MS-DOS 2.11 for the Tandy 2000!  It's byte-for-byte the same in MS-DOS 2.11.02 and MS-DOS 2.11.03.)

in your C:\CONFIG.SYS file, and ensure that the ANSI.SYS file is in your C:\ root directory.

-aquishix 2018-10-14

P.S.
This file was created with vi on a Tandy 2000.  ;)
