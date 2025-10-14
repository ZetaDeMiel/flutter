import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
//3.1 Importar libreria para Timer
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  //Cerebro de la logica de las animaciones
  StateMachineController? 
  controller; //El ? sirve para verificar que la variable no sea nulo
  //SMI: State Machine Input
  SMIBool? isChecking; //Activa el modo "Chismoso"
  SMIBool? isHandsUp; //Se tapa los ojos
  SMITrigger? trigSuccess; //Se emociona
  SMITrigger? trigFail; //Se pone sad

  //2.1 Variable para el seguimiento de los ojos
  SMINumber? numLook; //Sigue el movimiento del cursor

  // 1) FocusNode(Nodo donde esta el foco)
  final emailFocus = FocusNode();
  final passFocus = FocusNode();

  //3.2 Timer para detener la mirada al dejar de teclear
  Timer? _typingDebounce;

  // 1.2) Listeners (Oyentes, escuchadores)
  @override
  void initState() {
    super.initState();
    emailFocus.addListener(() {
      if (emailFocus.hasFocus) {
        //Manos abajo en email
        isHandsUp?.change(false); 
        //2.2 mirada neutral al enfocar email
        numLook?.value = 50.0;
        isHandsUp?.change(false);
      }
    });
    passFocus.addListener(() {
      isHandsUp?.change(passFocus.hasFocus); //Manos arriba en password
    });
  }

  @override
  Widget build(BuildContext context) {
    //MediaQuery Consulta el tamaño de la pantalla
    //Para obtener el tamaño de la pantalla del dips.
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      //Evita nudge o camaras frontales para moviles
      body: SafeArea(
        child: Padding(
          //Eje x/horizontal/derecha izquierda
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
              width: size.width,
              height: 200,
              child: RiveAnimation.asset(
                'assets/animated_login_character.riv',
                stateMachines: ["Login Machine"],
                //Al iniciarse
                onInit: (artboard){
                  controller = 
                  StateMachineController.fromArtboard(
                    artboard, 
                    "Login Machine",
                  );
                  //Verificar que inicio bien
                  if(controller == null) return;
                  artboard.addController(controller!,); // El ! Es para decirle que no es nulo
                  isChecking  = controller!.findSMI('isChecking');
                  isHandsUp   = controller!.findSMI('isHandsUp');
                  trigSuccess = controller!.findSMI('trigSuccess');
                  trigFail    = controller!.findSMI('trigFail');
                  // 2.3 Enlazar variable con la animacion
                  numLook     = controller!.findSMI('numLook');
                },
                ),
              ),
              //Espacio entre el oso y el texto email
              const SizedBox(height: 10),
              //Campo de texto del email
              TextField(
                focusNode: emailFocus, //Asigna el focusNode al TextField
                onChanged:(value) {
                  if (isHandsUp != null){
                    //2.4 Implementando numLook
                    //"Estoy escribiendo"
                    isChecking!.change(true);

                    //Ajuste de limites de 0 a 100
                    // 80 es una medida calibracion
                    final look = (value.length / 80.0 * 100.0).clamp(0.0, 100.0);
                    numLook?.value = look;

                    //3.3 Debounce: si vuelve a teclear, reinicia el contador
                    _typingDebounce?.cancel(); //Cancela cualquier timer existente
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      if (!mounted) {
                        return; //Si la pantalla se cierra
                      }
                      //Mirada neutra
                      isChecking?.change(false);
                    });
                  }
                  if (isChecking == null) return;
                  //Activa el modo chismoso
                  isChecking!.change(true);
                },

                //Para que aparezca @ en moviles
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email",
                  prefixIcon: const Icon(Icons.mail),
                  border: OutlineInputBorder(
                    //Esquinas redondeadas
                    borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
          
              const SizedBox(height: 10),
                TextField(
                  focusNode: passFocus,
                  onChanged:(value) {
                  if (isChecking != null){
                    //Tapar los ojos al escribir email
                    //isChecking!.change(false);
                  }
                  if (isHandsUp == null) return;
                  //Activa el modo chismoso
                  isHandsUp!.change(true);
                },

                obscureText: _obscurePassword,
                //Para que aparezca @ en moviles
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock), //Se puede poner password(para icono)
                  border: OutlineInputBorder(
                    //Esquinas redondeadas
                    borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(
                
                  width: size.width,
                  child: const Text(
                    "Forgot your password?",
                    //Alinear a la derecha
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                //Boton de login
                const SizedBox(height: 10),
                //Boton estilo Android
                MaterialButton(
                  minWidth: size.width,
                  height: 50,
                  color: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(12)
                  ),
                  onPressed: (){},
                  child: Text("Login",
                  style: TextStyle(
                    color: Colors.white)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: (){},
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: Colors.black,
                            //En negritas
                            fontWeight: FontWeight.bold,
                            //Subrayado
                            decoration: TextDecoration.underline,
                          ),
                        )
                      )
                    ]
                  )
                )
            ],
          ),
        )
        )
    );
  }

  // 4) Liberacion de recursos / limpieza de focos
  @override
  void dispose() {
    emailFocus.dispose();
    passFocus.dispose();
    super.dispose();
  }
}