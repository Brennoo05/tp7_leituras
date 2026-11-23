// =============================================================
// TP7 - App de Organização de Leituras
// Integrante: Brenno Gonçalves Rodrigues
// =============================================================


import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LeiturasApp());
}

// -------------------------------------------------------------
// App
// -------------------------------------------------------------
class LeiturasApp extends StatelessWidget {
  const LeiturasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minhas Leituras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// -------------------------------------------------------------
// Modelo
// -------------------------------------------------------------
const List<String> statusLeitura = ['Quero ler', 'Lendo', 'Concluído'];

class Livro {
  final String titulo;
  final String autor;
  final String status;

  Livro({
    required this.titulo,
    required this.autor,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'autor': autor,
        'status': status,
      };

  factory Livro.fromMap(Map<String, dynamic> map) => Livro(
        titulo: map['titulo'] ?? '',
        autor: map['autor'] ?? '',
        status: map['status'] ?? statusLeitura.first,
      );

  String toJson() => jsonEncode(toMap());

  factory Livro.fromJson(String json) =>
      Livro.fromMap(jsonDecode(json) as Map<String, dynamic>);
}

// Título da AppBar com o nome do integrante (usado nas duas telas).
Widget tituloAppBar(String titulo) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(titulo),
      const Text(
        'Brenno Gonçalves Rodrigues',
        style: TextStyle(fontSize: 13),
      ),
    ],
  );
}

// -------------------------------------------------------------
// Tela inicial: lista de livros (ListView)
// -------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _chaveLivros = 'livros';

  final List<Livro> _livros = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarLivros(); // recupera os dados ao iniciar o app
  }

  Future<void> _carregarLivros() async {
    final prefs = await SharedPreferences.getInstance();
    final listaSalva = prefs.getStringList(_chaveLivros) ?? [];

    setState(() {
      _livros
        ..clear()
        ..addAll(listaSalva.map((json) => Livro.fromJson(json)));
      _carregando = false;
    });
  }

  Future<void> _salvarLivros() async {
    final prefs = await SharedPreferences.getInstance();
    final listaJson = _livros.map((livro) => livro.toJson()).toList();
    await prefs.setStringList(_chaveLivros, listaJson);
  }

  Future<void> _abrirCadastro() async {
    final novoLivro = await Navigator.push<Livro>(
      context,
      MaterialPageRoute(builder: (context) => const CadastroPage()),
    );

    if (novoLivro == null) return; // voltou sem salvar

    setState(() {
      _livros.add(novoLivro);
    });
    await _salvarLivros();

    if (!mounted) return;
    _mostrarMensagem('"${novoLivro.titulo}" adicionado à lista!');
  }

  Future<void> _removerLivro(int index) async {
    final removido = _livros[index];
    setState(() {
      _livros.removeAt(index);
    });
    await _salvarLivros();

    if (!mounted) return;
    _mostrarMensagem('"${removido.titulo}" removido da lista.');
  }

  Future<void> _confirmarRemocao(int index) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover livro'),
        content: Text('Deseja remover "${_livros[index].titulo}" da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    Future<void> _alterarStatus(int index) async {
    final atual = _livros[index];
    final proximo = statusLeitura[
        (statusLeitura.indexOf(atual.status) + 1) % statusLeitura.length];

    setState(() {
      _livros[index] =
          Livro(titulo: atual.titulo, autor: atual.autor, status: proximo);
    });
    await _salvarLivros();

    if (!mounted) return;
    _mostrarMensagem('"${atual.titulo}" agora está como "$proximo".');
  }

    
    if (confirmou == true) {
      await _removerLivro(index);
    }
  }
  
  void _mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  IconData _iconeDoStatus(String status) {
    switch (status) {
      case 'Lendo':
        return Icons.menu_book;
      case 'Concluído':
        return Icons.check_circle;
      default:
        return Icons.bookmark_border;
    }
  }

  Widget _construirCorpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_livros.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum livro cadastrado ainda.\nToque em + para adicionar.',
          textAlign: TextAlign.center,
        ),
      );
    }

        final concluidos =
        _livros.where((livro) => livro.status == 'Concluído').length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '${_livros.length} livro(s) • $concluidos concluído(s)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _livros.length,
            itemBuilder: (context, index) {
              final livro = _livros[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  onTap: () => _alterarStatus(index),
                  leading: Icon(_iconeDoStatus(livro.status)),
                  title: Text(livro.titulo),
                  subtitle: Text('${livro.autor} • ${livro.status}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remover',
                    onPressed: () => _confirmarRemocao(index),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: tituloAppBar('Minhas Leituras')),
      body: _construirCorpo(),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCadastro,
        tooltip: 'Adicionar livro',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// -------------------------------------------------------------
// Segunda tela: cadastro de livro
// -------------------------------------------------------------
class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _tituloController = TextEditingController();
  final _autorController = TextEditingController();
  String _status = statusLeitura.first;

  @override
  void dispose() {
    _tituloController.dispose();
    _autorController.dispose();
    super.dispose();
  }

  void _salvar() {
    final titulo = _tituloController.text.trim();
    final autor = _autorController.text.trim();

    if (titulo.isEmpty || autor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o título e o autor.')),
      );
      return;
    }

    Navigator.pop(
      context,
      Livro(titulo: titulo, autor: autor, status: _status),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: tituloAppBar('Cadastrar Livro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _tituloController,
            decoration: const InputDecoration(
              labelText: 'Título',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _autorController,
            decoration: const InputDecoration(
              labelText: 'Autor',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Status da leitura'),
          DropdownButton<String>(
            value: _status,
            isExpanded: true,
            items: statusLeitura
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (valor) {
              if (valor != null) {
                setState(() {
                  _status = valor;
                });
              }
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.save),
            label: const Text('Salvar livro'),
          ),
        ],
      ),
    );
  }
}
