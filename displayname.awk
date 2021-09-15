@include "sliic/libLocProperties"
@include "sliic/libParserFilePath"
@include "sliic/libJavaParser"

BEGIN {
 findFiles(msgs_paths);
 if (!isarray(msgs_paths)) {
   print "Erro: Nenhum arquivo de dicionário encontrado" > "/dev/tty";
   exit 1;
 }
}

BEGINFILE {
  parserFilePath(FILENAME, aMetaFile);
  MsgProp = locProperties(aMetaFile, msgs_paths);
  if (!MsgProp) {
    print "Erro: Não foi encontrado nenhum arquivo de dicionário." > "/dev/tty";
    exit 1;
  }
  cntClass = 0;
}

/package/ {
  if(!(package = getPackage($0))) {
    print "Erro: package não encontrado" > "/dev/tty";
    exit 1;
  }
}

/^(public|private|protected) .*class/ {
  if (!(classe[cntClass++] = getClass($0))) {
    print "Erro: Nome da classe não foi encontrado." > "/dev/tty";
    exit 1;
  }
}

/^(public|private|protected) enum/ {
  if (!(classe[cntClass++] = getEnum($0))) {
    print "Erro: Nome do enum não foi encontrado." > "/dev/tty";
    exit 1;
  }
}

ENDFILE {
  if (cntClass > 1) {
    printf "Aviso: Encontradas as seguintes classes e/ou enums aninhados: " > "/dev/tty";
    for (i in classe) {
      printf "%s ", classe[i] > "/dev/tty";
    }
  printf "\n" > "/dev/tty";
  }
}
