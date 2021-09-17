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

/^\s*?@DisplayName/ {
  texto = getTextoEntreAspas($0);
  next;
}

/^(public|private|protected) .*class/ {
  classe[cntClass++] = getClass($0);
  flag[0] = "gerarCodigo";
  flag[1] = "classe";
}

/^(public|private|protected) enum/ {
  if (!(classe[cntClass++] = getEnum($0))) {
    print "Erro: Nome do enum não foi encontrado." > "/dev/tty";
    exit 1;
  }
}

$0 ~ /(public|private|protected).* ((get)|(is))\w+\(/ && 
$0 !~ /getId/ &&
$0 !~ /^has+/ &&
$0 !~ /getDataAlteracaoAuditoria/ &&
$0 !~ /getUsuarioAuditoria/ {
  flag[0] = "gerarCodigo";
  flag[1] = "metodo";
}

flag[0] == "gerarCodigo" {
   fmt = removerIdentacao($0);
   print " Instrução:", FNR, fmt > "/dev/tty";
   
   if(!texto) {
     texto = getTexto("Entre o texto do código:");
   }

   displayName($0, package"."classe[0], texto, flag[1]);
   codigo = getCodigo();
   printf " Código: %s\n\n", codigo  > "/dev/tty";
   
   if ("inplace::begin" in FUNCTAB) {
     printf ("%s\r\n", codigo) >> MsgProp;
   }
   delete flag;
   texto = "";
}

{
  if ("inplace::begin" in FUNCTAB) {    
    printf "%s%s", $0, RT;
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

END {
  convertUtf8ToIso8859();
}
