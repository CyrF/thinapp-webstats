@echo off

SET appli=%~nx1
SET chemn=%~1
Echo Va creer l'archive "%appli%.zst"
Echo avec le contenu de "%chemn%" ?
Echo.
Echo Fermer cette fenetre pour annuler ou appuyer sur une touche pour commencer...
pause >nul


7za.exe a -m0=zstd -mx1 "%appli%.zst" "%chemn%"