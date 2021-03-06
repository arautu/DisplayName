# Arquivo: l_displayname.awk 
# Descrição: Libs exclusivas de displayname.awk

BEGINFILE {
  save_sorted = "";
  id = "";
  codigo = "";
}

# Obtém o texto entre aspas
# Argumentos:
# * line: Linha contendo texto entre aspas.
# Retorno:
# * O texto que está entre aspas, se existir ou nulo, caso contrário.
function getTextoEntreAspas(line,   i, arr, seps, texto) {
  sort_init("@ind_num_asc");
  split(line, arr, "\"", seps);

  for (i in seps) {
    if (seps[i] ~ "\"") {
      texto = arr[i+1];
      break
    }
  }
  sort_end();
  return texto;
}

# Interage com o usuário, através do terminal, para obter o texto descrito
# na mensagem.
# Argumentos:
# * aviso: Texto com a instrução sobre o dado que o usuário deve preencher.
# Retorno:
# O dado fornecido pelo usuário.
function getTexto(aviso,   Oldrs, id) {
  Oldrs = RS;
  RS = "\n";

  printf "  " > "/dev/tty";
  printf " %s ", aviso > "/dev/tty";
  getline texto < "/dev/stdin";

  RS = Oldrs;

  return texto;
}

# Recebe como parâmetro um método 'getter' ou 'is' e descobre a propriedade.
# Argumentos:
# * lineMetodo: Método 'getter' ou 'is', ex: 'public getValor()'.
# Retorno:
# * Retorna o nome da propriedade referente ao método.
function getPropriedadePeloMetodo(lineMetodo,   i, propriedade,  arr) {
  split(lineMetodo, arr, "[ (]");
  for (i in arr) {
    if (arr[i] ~ /^((get)|(is))/) {
      sub(/^((get)|(is))/, "", arr[i]) 
      propriedade = arr[i];
      propriedade = tolower(substr(propriedade, 1, 1)) substr(propriedade, 2);
      break;
    }
  }
  return propriedade;
}

# Salva o valor de 'sorted_in' na variável global 'save_sorted', antes
# de mudá-lo para o valor desejado.
# Argumentos
# * ordem: Texto contendo a ordem do array, ex: "@ind_num_asc".
function sort_init(ordem) {
  save_sorted = "";
  
  if ("sorted_in" in PROCINFO) {
    save_sorted = PROCINFO["sorted_in"]
  }
  PROCINFO["sorted_in"] = ordem
}

# Recupera da variável global 'save_sorte' os valores anteriores de
# ordenação dos arrays.
function sort_end() {
  if (save_sorted)
  PROCINFO["sorted_in"] = save_sorted
}
