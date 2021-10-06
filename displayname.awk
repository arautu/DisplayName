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
  cnt = 0;
  prefixo = "";
  id = "";
  package = "";
  class = "";

  print "\n==== Criação de códigos de dicionário de propriedades  ====\n" > "/dev/tty";
  print "Arquivo:", FILENAME > "/dev/tty";
  printf "Properties: %s\n\n", MsgProp > "/dev/tty";
}

/{/ && cnt++ ||
/}/ && cnt-- {}

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

/^(public|private|protected).* \<class\>/ {
  class = getClass($0);
  prefixo = package"."class;
  flag[0] = "gerarCodigo";
  flag[1] = "classe";
}

/^\s+.* \<class\>/ {
  cc = cnt - 1;
  
  nestedClass = getClass($0);
  prefixo = package"."class"$"nestedClass;
  flag[0] = "gerarCodigo";
  flag[1] = "classe";
}

/^\s+.* \<class\>/, cnt==cc {
  if (cnt == cc) {
    nestedClass = "";
    prefixo = package"."class;
  }
}

/^\s+(public|private|protected).* \<enum\>/ {
  enum = getEnum($0);
}

$0 ~ /(public|private|protected).* ((get)|(is))\w+\(/ && 
$0 !~ /getId\>/ &&
$0 !~ /^has+/ &&
$0 !~ /getDataAlteracaoAuditoria/ &&
$0 !~ /getUsuarioAuditoria/ {
  flag[0] = "gerarCodigo";
  flag[1] = "metodo";
  id = "." getPropriedadePeloMetodo($0);
}

flag[0] == "gerarCodigo" {
   fmt = removerIdentacao($0);
   print " Instrução:", FNR, fmt > "/dev/tty";
   
   if(!texto) {
     texto = getTexto("Entre o texto do código:");
   }
   codigo = prefixo id "=" texto;
   printf " Código: %s\n\n", codigo  > "/dev/tty";
   
   if ("inplace::begin" in FUNCTAB) {
     printf ("%s\r\n", codigo) >> MsgProp;
   }
   delete flag;
   texto = "";
   id = "";
}

{
  if ("inplace::begin" in FUNCTAB) {    
    printf "%s%s", $0, RT;
  }
}

END {
  convertUtf8ToIso8859();
}
