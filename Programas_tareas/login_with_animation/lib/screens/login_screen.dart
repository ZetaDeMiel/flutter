import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  bool _obscurePassword = true;

  //Cerebro de la logica de las animaciones
  StateMachineController? controller;
  //SMI: State Machine Input
  SMIBool? isChecking; //Activa el modo "Chismoso"
  SMIBool? isHandsUp; //Se tapa los ojos
  SMITrigger? trigSuccess; //Se emociona
  SMITrigger? trigFail; //Se pone sad

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
                  artboard.addController(controller!);
                  isChecking  = controller!.findSMI('isChecking');
                  isHandsUp   = controller!.findSMI('isHandsUp');
                  trigSuccess = controller!.findSMI('trigSuccess');
                  trigFail    = controller!.findSMI('trigFail');
                }
                ),
              ),
              //Espacio entre el oso y el texto email
              const SizedBox(height: 10),
              //Campo de texto del email
              TextField(
                onChanged:(value) {
                  if (isHandsUp != null){
                    //No tapar los ojos al escribir email
                    isHandsUp!.change(false);
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
                  onChanged:(value) {
                  if (isChecking != null){
                    //No tapar los ojos al escribir email
                    isChecking!.change(false);
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
                  onPressed: (){
                    //TODO:
                  },
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
}