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

  // 5.1 Variable para controlar si el boton Login esta cargando
  // Sirve para mostrar un spinner y evitar que el usuario presione varias veces
  bool _isLoading = false;

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

  // 3.2 Timer para detener la mirada al dejar de teclear
  Timer? _typingDebounce;

  // 4.1 Controllers
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // 4.2  Errores para mostrar en la UI
  String? emailError;
  String? passError;

// 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  //4.4 Acción al botón
  void _onLogin() async {
    // 5.2 Evita que se presione el boton mientras esta cargando
    // Si ya esta procesando, no hace nada
    if (_isLoading) return;

    // 5.3 Activar estado de carga y actualizar UI
    setState(() {
      _isLoading = true;
    });

    // trim (recortar) sirve para eliminar espacios en un campo de texto
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    // Recalcular errores dinamicamente (solo el primero aplicable)
    String? eError;
    if (email.isNotEmpty && !isValidEmail(email)) {
      eError = 'Email invalido';
    }

    String? pError;
    if(pass.isNotEmpty && pass.length < 8) {
      pError = 'Debe tener al menos 8 caracteres';
    } else if (!RegExp(r'[A-Z]').hasMatch(pass)) {
      pError = 'Debe tener una mayuscula';
    } else if (!RegExp(r'[a-z]').hasMatch(pass)) {
      pError = 'Debe tener al menos una minuscula';
    } else if (!RegExp(r'\d').hasMatch(pass)) {
      pError = 'Debe incluir un numero';
    } else if (!RegExp(r'[^A-Za-z0-9]').hasMatch(pass)) {
      pError = 'Debe incluir un caracter especial';
    }
    // 4.5 Para avisar que hubo un cambio
    setState(() {
      emailError = eError;
      passError = pError;
    });
    // 4.6 Cerrar el teclado y bajar
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    isChecking?.change(false);
    isHandsUp?.change(false);
    numLook?.value = 50.0; // Mirada neutral

    // 5.4 Esperar hasta el siguiente frame completo antes de disparar el trigger
    // Esto garantiza que Rive procese la animacion de bajar lar mano antes del trigger
    await Future<void>.delayed(
      const Duration(milliseconds:600),
    );
    //Se le puso esa contidad porque con el tiempo para la aniamcion de bajar las manos

    // 5.5 Simular tiempo de carga (~1 segundo)
    await Future.delayed (const Duration(seconds: 1));

    //4.7 Activar triggers
    if (eError == null && pError == null) {
      trigSuccess?.fire();
    } else {
      trigFail?.fire();
    }

  //5.6 Desactivar el estado de carga al finalizar
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
                //4.8 Enlazar controller al TextField
                controller: emailCtrl,
                onChanged:(value) {

                    //2.4 Implementando numLook
                    //"Estoy escribiendo"
                    isChecking!.change(true);

                    // 5.7 Validacion dinamica de email mientras se escriba
                    String? eError;
                    if (value.isNotEmpty && !isValidEmail(value)) {
                      eError = 'Email invalido';
                    }

                    //Se borro el error si el campo esta vacio
                    if (value.isEmpty) {
                      eError = null;
                    }
                    
                    setState(() {
                      emailError = eError;
                    });

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
                  
                  if (isChecking == null) return;
                  //Activa el modo chismoso
                  isChecking!.change(true);
                },

                //Para que aparezca @ en moviles
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  // 4.9 Mostrar el texto del error
                  errorText: emailError,
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
                  // 4.8 Enlazar el controller al TextField
                  controller: passCtrl,
                  onChanged:(value) {
                  
                  //5.8 Validacion dinamica de password mientras se escribe
                  String? pError;
                  if (value.isNotEmpty && value.length < 8) {
                    pError = 'Debe tener al menos 8 caracteres';
                  } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    pError = 'Debe tener una mayuscula';
                  } else if (!RegExp(r'[a-z]').hasMatch(value)) {
                    pError = 'Debe tener al menos una minuscula';
                  } else if (!RegExp(r'\d').hasMatch(value)) {
                    pError = 'Debe incluir un numero';
                  } else if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
                    pError = 'Debe incluir un caracter especial';
                  }

                  //Se borra el error si el campo esta vacio
                  if (value.isEmpty) {
                    pError = null;
                  }

                  setState(() {
                    passError = pError;
                  });

                  if (isHandsUp == null) return;
                  //Activa el modo chismoso
                  isHandsUp!.change(true);
                },

                obscureText: _obscurePassword,
                //Para que aparezca @ en moviles
                decoration: InputDecoration(
                  // 4.9 Mostrar el texto del error
                  errorText: passError,
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
                const SizedBox(height: 10),

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
                    borderRadius: BorderRadiusGeometry.circular(12),
                  ),
                  
                  //5.7 Deshabilita el boton mientras carga
                  onPressed: _isLoading ? null : _onLogin,
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.blue)
                    : const Text(
                      "Login",
                      style: TextStyle(color: Colors.white),
                    ),

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
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  // 4) Liberacion de recursos / limpieza de focos
  @override
  void dispose() {
    //4.11 Limpieza de los controllers
    emailCtrl.dispose();
    passCtrl.dispose();
    emailFocus.dispose();
    passFocus.dispose();
    _typingDebounce?.cancel();
    super.dispose();
  }
}