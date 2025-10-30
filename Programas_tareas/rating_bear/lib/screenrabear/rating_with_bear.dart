// Importa el paquete principal de Flutter que contiene widgets, estilos y herramientas
// necesarias para construir interfaces gráficas.
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:flutter/services.dart'
    show rootBundle; // Nuevo: para leer archivos de assets en memoria

// Definición de un widget con estado llamado "RatingWithBear".
// Es un StatefulWidget porque el número de estrellas seleccionadas puede cambiar dinámicamente.
class RatingWithBear extends StatefulWidget {
  const RatingWithBear({super.key});

  // Crea el estado asociado al widget.
  @override
  State<RatingWithBear> createState() => _RatingWithBearState();
}

// Clase que define el estado del widget.
class _RatingWithBearState extends State<RatingWithBear> {
  // NUEVO ENFOQUE: trabajamos con 2 artboards
  Artboard?
  _master; // "Molde" original cargado desde el .riv (NO se muestra nunca)
  Artboard?
  _current; // Copia activa/visible; se reemplaza para interrumpir animaciones

  // Inputs de la State Machine (triggers de Rive)
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  int _rating = 0;

  // ---- CARGA DEL ARCHIVO ----
  @override
  void initState() {
    super.initState();
    _loadRive(); // Nuevo: cargamos el .riv manualmente (ya no usamos RiveAnimation.asset)
  }

  Future<void> _loadRive() async {
    // MUY IMPORTANTE EN WEB/ESCRITORIO:
    // Inicializa el motor de Rive ANTES de importar archivos .riv
    await RiveFile.initialize();

    // Leemos el archivo .riv desde assets en memoria (bytes crudos)
    final bytes = await rootBundle.load('assets/animated_login_character.riv');

    // Importamos esos bytes a un RiveFile (parseo del formato .riv)
    final file = RiveFile.import(bytes.buffer.asByteData());

    // Obtenemos el artboard principal del archivo
    final main = file.mainArtboard;

    // Guardamos el artboard original como "molde" para clonar instancias limpias
    setState(() {
      _master = main;
    });

    // Creamos la primera instancia visible y conectamos la State Machine
    _rebuildArtboardAndAttachController();
  }

  // ---- RECONSTRUIR STATE MACHINE (INTERRUPCIÓN REAL) ----
  void _rebuildArtboardAndAttachController() {
    if (_master == null) return;

    // Clona el artboard original (_master) para empezar SIEMPRE desde estado limpio
    final fresh = _master!.instance();

    // Busca dentro del Artboard un State Machine con ese nombre
    // Si lo encuentra, crea un controlador que permite manejar los inputs
    // fres: es un Artboard recienc clonado del archivo .riv
    final ctrl = StateMachineController.fromArtboard(fresh, 'Login Machine');

    // Conectamos el controlador a la instancia "fresh"
    fresh.addController(ctrl!);

    // Obtenemos los inputs concretos de tipo Trigger por nombre exacto
    _trigSuccess = ctrl.findSMI<SMITrigger>('trigSuccess');
    _trigFail = ctrl.findSMI<SMITrigger>('trigFail');
    debugPrint('Inputs -> success: $_trigSuccess | fail: $_trigFail');

    // Hacemos visible esta nueva instancia en pantalla (interrumpe la anterior)
    setState(() => _current = fresh);
  }

  // ---- REINICIAR + DISPARAR TRIGGER ----
  Future<void> _restartAndFire({required bool happy}) async {
    // Creamos una nueva instancia limpia y re-adjuntamos la State Machine
    _rebuildArtboardAndAttachController();

    // Esperamos un frame para asegurar que el nuevo artboard ya se montó en el árbol
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ahora sí, disparamos el trigger correspondiente
      if (happy) {
        _trigSuccess?.fire();
        debugPrint('➡️ fire trigSuccess');
      } else {
        _trigFail?.fire();
        debugPrint('➡️ fire trigFail');
      }
    });
  }

  // Reinicia el artboard sin disparar ninguna animación
  Future<void> _restartWithoutAnimation() async {
    // Crea un nuevo artboard limpio (como los otros métodos)
    _rebuildArtboardAndAttachController();

    // Espera un frame para asegurarte de que se monte correctamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // No disparamos ningún trigger aquí, simplemente se queda en idle
    });
  }

  // Método build: construye la interfaz visual del widget cada vez que cambia el estado.
  @override
  Widget build(BuildContext context) {
    // Obtiene las dimensiones actuales de la pantalla del dispositivo.
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,

      // SafeArea evita que el contenido se superponga con las áreas del sistema (notch, barra superior, etc.).
      body: SafeArea(
        // Padding aplica márgenes horizontales a todo el contenido.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),

          // Column organiza todos los widgets de forma vertical (uno debajo del otro).
          child: Column(
            // Centra todos los elementos verticalmente en la pantalla.
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: size.width, // Ocupa todo el ancho de la pantalla.
                height: 200, // Altura fija para la animación.
                // Mientras _current es null mostramos un loader (el .riv está cargando)
                child: _current == null
                    ? const Center(child: CircularProgressIndicator())
                    // Nuevo: usamos el widget Rive con un "artboard" ya construido por nosotros
                    : Rive(artboard: _current!, fit: BoxFit.contain),
              ),

              const SizedBox(height: 25),

              // Título principal ("Enjoying Sounter?")
              const Text(
                "Enjoying Sounter?",
                style: TextStyle(
                  fontSize: 22, // Tamaño de fuente.
                  fontWeight: FontWeight.bold, // Negrita.
                  color: Colors.black87, // Color del texto.
                ),
              ),

              const SizedBox(height: 8),

              // Texto explicativo debajo del título.
              const Text(
                "With how many stars do you rate your experience.\nTap a star to rate!",
                textAlign: TextAlign.center, // Centra el texto horizontalmente.
                style: TextStyle(
                  fontSize: 15, // Tamaño de la fuente.
                  color: Colors.grey, // Color gris para menor énfasis.
                  height: 1.4, // Espaciado entre líneas.
                ),
              ),

              const SizedBox(height: 25),

              // Estrellas: la lógica dispara _restartAndFire(...) para interrumpir y animar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final index = i + 1;
                  final filled = _rating >= index;
                  return IconButton(
                    iconSize: 44,
                    color: filled ? Colors.amber : Colors.grey,
                    icon: Icon(filled ? Icons.star : Icons.star_border),
                    onPressed: () {
                      setState(() => _rating = index);

                      // Aquí decidimos qué trigger disparar
                      if (_rating >= 4) {
                        _restartAndFire(happy: true); // éxito/alegre
                      } else if (_rating <= 2) {
                        _restartAndFire(happy: false); // fallo/triste
                      } else {
                        _restartWithoutAnimation();
                      }
                    },
                  );
                }),
              ),

              const SizedBox(height: 30),

              // Botones extra de tu UI (sin relación con Rive)
              MaterialButton(
                minWidth: size.width,
                height: 50,
                color: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(12),
                ),
                onPressed: () {},
                child: const Text(
                  'Rate Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              MaterialButton(
                minWidth: size.width,
                height: 50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(12),
                ),
                onPressed: () {},
                child: const Text(
                  'NO THANKS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}