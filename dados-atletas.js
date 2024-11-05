// Definição da classe Atleta
class Atleta {
    // Construtor da classe Atleta, que recebe os atributos necessários
    constructor(nome, idade, peso, altura, notas) {
      this.nome = nome;
      this.idade = idade;
      this.peso = peso;
      this.altura = altura;
      this.notas = notas;
    }
  
    // Método para calcular a categoria do atleta
    calculaCategoria() {
      if (this.idade >= 9 && this.idade <= 11) {
        return 'Infantil';
      } else if (this.idade >= 12 && this.idade <= 13) {
        return 'Juvenil';
      } else if (this.idade >= 14 && this.idade <= 15) {
        return 'Intermediário';
      } else if (this.idade >= 16 && this.idade <= 30) {
        return 'Adulto';
      } else {
        return 'Sem categoria';
      }
    }
  
    // Método para calcular o IMC do atleta
    calculaIMC() {
      return this.peso / (this.altura * this.altura);
    }
  
    // Método para calcular a média válida das notas
    calculaMediaValida() {
      // Ordena as notas em ordem crescente
      let notasOrdenadas = this.notas.sort((a, b) => a - b);
      
      // Elimina a maior e a menor nota (primeira e última após o sort)
      let notasValidas = notasOrdenadas.slice(1, 4);
      
      // Calcula a soma das notas válidas
      let soma = notasValidas.reduce((acumulado, nota) => acumulado + nota, 0);
      
      // Retorna a média válida
      return soma / notasValidas.length;
    }
  
    // Métodos para obter os dados do atleta
    obtemNomeAtleta() {
      return this.nome;
    }
  
    obtemIdadeAtleta() {
      return this.idade;
    }
  
    obtemPesoAtleta() {
      return this.peso;
    }
  
    obtemNotasAtleta() {
      return this.notas.join(',');
    }
  
    obtemCategoria() {
      return this.calculaCategoria();
    }
  
    obtemIMC() {
      return this.calculaIMC();
    }
  
    obtemMediaValida() {
      return this.calculaMediaValida();
    }
  }
  
  // Criando um objeto atleta com os dados fornecidos
  const atleta = new Atleta("Cesar Abascal", 30, 80, 1.70, [10, 9.34, 8.42, 10, 7.88]);
  
  // Exibindo as informações do atleta
  console.log(`Nome: ${atleta.obtemNomeAtleta()}`);
  console.log(`Idade: ${atleta.obtemIdadeAtleta()}`);
  console.log(`Peso: ${atleta.obtemPesoAtleta()}`);
  console.log(`Altura: ${atleta.altura}`);
  console.log(`Notas: ${atleta.obtemNotasAtleta()}`);
  console.log(`Categoria: ${atleta.obtemCategoria()}`);
  console.log(`IMC: ${atleta.obtemIMC()}`);
  console.log(`Média válida: ${atleta.obtemMediaValida().toFixed(8)}`);
  