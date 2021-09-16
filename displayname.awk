@include "sliic/libLocProperties"
@include "sliic/libParserFilePath"
@include "sliic/libJavaParser"
@include "sliic/libConvIsoUtf"
@include "l_displayname" 

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
  convertIso8859ToUtf8();
  cntClass = 0;
  package = "";
  delete classe;

  print "\n==== Criação de códigos de dicionário de propriedades  ====\n" > "/dev/tty";
  print "Arquivo:", FILENAME > "/dev/tty";
  printf "Properties: %s\n\n", MsgProp > "/dev/tty";
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

/^\s*?@DisplayName/ {
  fmt = removerIdentacao($0);
  print " Instrução:", FNR, fmt > "/dev/tty";

  texto = getTextoEntreAspas($0);
  
  while (getline) {
    fmt = removerIdentacao($0);
    printf "            %s %s\n", FNR, fmt > "/dev/tty";
    
    if (match($0, /^\s+?\w+.*\(.*\)/)) {
      displayName($0, package"."classe[0], texto);
      break;
    }
  }
  codigo = getCodigo();
  printf " Código: %s\n\n", codigo  > "/dev/tty";
  next;
}

$0 ~ /(public|private|protected).* ((get)|(is))\w+\(/ && 
$0 !~ /getId/ &&
$0 !~ /^has+/ &&
$0 !~ /getDataAlteracaoAuditoria/ &&
$0 !~ /getUsuarioAuditoria/ {

  fmt = removerIdentacao($0);
  print " Instrução:", FNR, fmt > "/dev/tty";
  
  texto = getTexto("Entre o id do código:");
  displayName($0, package"."classe[0], texto);
  codigo = getCodigo();
  printf " Código: %s\n\n", codigo  > "/dev/tty";
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

END {
  convertUtf8ToIso8859();
}
