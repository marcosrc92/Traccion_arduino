// Need G4P library
import g4p_controls.*;
import java.awt.*;
import processing.serial.*;
import grafica.*;
import java.awt.image.BufferedImage;

//Serial communication
Serial myPort;
int baudrate = 115200;

//Text for each label
String str_title = "~ AXIALATOR ~";
String str_1st_msg = "First Message";
String str_2nd_msg = "Second Message";
String str_status = "System Status";
String str_btn_start = "Start";

//Text for information dialog
String msgBx_title = "Title";
String msgBx_msg = "Information";

//Led status
PImage img_led;

//System checks
boolean system_detected = false;
boolean system_paired = false;
boolean at_least_1_read = false;
boolean test_running = false;

//Custom variables
//Readings
float load = 0.0;
float angle = 0.0;
float lastAngle = 0.0;
float mm = 0.0;
float angle2mm = 0.0555555555555556/2; //1 encoder degree = 0.0555 mm
float time = 0.0;
float timeOffset = 0.0;
//Output
PrintWriter outputFile;
//Real time plot_carga_deformacion
GPlot plot_carga_deformacion;
GPlot plot_carga_tiempo;
GPlot plot_deformacion_tiempo;
GPointsArray carga_deformacion;
GPointsArray carga_tiempo;
GPointsArray deformacion_tiempo;

public void setup() {
  size(960, 860, JAVA2D);
  //480x430 GUI (left, top)
  //480x430 plot_carga_deformacion carga_deformacion (right, top)
  //480x430 plot_carga_deformacion carga_tiempo (left, bottom)
  //480x430 plot_carga_deformacion deformacion_tiempo (right, bottom)
  createGUI();
  customGUI();  
  // Place your setup code here
  setSerialPort(myPort);
  outputFile = createWriter("AXIALATOR_resultados.txt");
  outputFile.println("Carga(Kg) Deformacion(mm) Tiempo(s)");
  plot_carga_deformacion = new GPlot(this);
  plot_carga_tiempo = new GPlot(this);
  plot_deformacion_tiempo = new GPlot(this);
  carga_deformacion = new GPointsArray();
  carga_tiempo = new GPointsArray();
  deformacion_tiempo = new GPointsArray();
  carga_deformacion.add(0, 0.0);
  carga_tiempo.add(0, 0.0);
  deformacion_tiempo.add(0, 0.0);
  plot_carga_deformacion.setPos(480, 0);
  plot_carga_deformacion.setOuterDim(480, 430);
  plot_carga_deformacion.setTitleText("Esfuerzo - Deformación");
  plot_carga_deformacion.getXAxis().setAxisLabelText("Milímetros");
  plot_carga_deformacion.getYAxis().setAxisLabelText("Kilogramos");
  plot_carga_deformacion.setPointSize(0); 
  plot_carga_deformacion.defaultDraw();
  plot_carga_tiempo.setPos(0, 430);
  plot_carga_tiempo.setOuterDim(480, 430);
  plot_carga_tiempo.setTitleText("Evolución de la carga");
  plot_carga_tiempo.getXAxis().setAxisLabelText("Segundos");
  plot_carga_tiempo.getYAxis().setAxisLabelText("Kilogramos");
  plot_carga_tiempo.setPointSize(0);
  plot_carga_tiempo.setPoints(carga_tiempo);
  plot_carga_tiempo.defaultDraw();
  plot_deformacion_tiempo.setPos(480, 430);
  plot_deformacion_tiempo.setOuterDim(480, 430);
  plot_deformacion_tiempo.setTitleText("Evolución de la deformación");
  plot_deformacion_tiempo.getXAxis().setAxisLabelText("Segundos");
  plot_deformacion_tiempo.getYAxis().setAxisLabelText("Milímetros");
  plot_deformacion_tiempo.setPointSize(0);
  plot_deformacion_tiempo.setPoints(deformacion_tiempo);
  plot_deformacion_tiempo.defaultDraw();
  

}

public void draw() {

  background(230);

  //Connection status
  if (system_detected) {
    img_led = loadImage("/data/green_led.png");
    str_status = "Estado: conectado.";
  } else {
    img_led = loadImage("/data/red_led.png");
    str_status = "Estado: no conectado.";
    //Try to reconnect...
    setSerialPort(myPort);
  }
  image(img_led, 160, 227);

  //Start/Stop button
  if (test_running)
    str_btn_start = "Finalizar";
  else
    str_btn_start = "Comenzar"; 

  //Messages management
  if (!system_detected) {
    str_1st_msg = "Sistema no detectado. Compruebe la conexión.";
    str_2nd_msg = "Pulse en el botón Ayuda para más información.";
  } 
  else {
    if (!at_least_1_read) {
        str_1st_msg = "Tarando la célula de carga.";
        str_2nd_msg = "Por favor, no aplique ninguna carga aún...";
    } 
    else {
      if (!test_running) {
      str_1st_msg = "Pulse Comenzar para iniciar la lectura.";
      str_2nd_msg = "Pulse el botón Ayuda para obtener más información.";
      }
    }
  }


  //Finally update GUI
  customGUI();  
  plot_carga_deformacion.setPoints(carga_deformacion);
  plot_carga_tiempo.setPoints(carga_tiempo);
  plot_deformacion_tiempo.setPoints(deformacion_tiempo);
  plot_carga_deformacion.defaultDraw();
  plot_carga_tiempo.defaultDraw();
  plot_deformacion_tiempo.defaultDraw();
  line(0,0,960,0);
  line(0,0,0,860);
  line(959,0,959,860);
  line(480,0,480,860);
  line(0,430,960,430);
  line(0,859,959,859);
}

//Customise the GUI controls
public void customGUI() {
  surface.setTitle(str_title);
  lbl_title.setText(str_title);
  lbl_title.setFont(new Font("Calibri", Font.ITALIC, 30));
  lbl_1st_msg.setText(str_1st_msg);
  lbl_1st_msg.setFont(new Font("Calibri", Font.PLAIN, 20));
  lbl_2nd_msg.setText(str_2nd_msg);
  lbl_2nd_msg.setFont(new Font("Calibri", Font.PLAIN, 20));
  lbl_status.setText(str_status);
  lbl_status.setFont(new Font("Calibri", Font.PLAIN, 17));
  btn_start.setText(str_btn_start);
  btn_start.setFont(new Font("Calibri", Font.PLAIN, 20));
}

//////////////////////////////////
// TRY TO CONNECT TO THE DEVICE //
//////////////////////////////////
public void setSerialPort(Serial myPort) {
  if (!(Serial.list().length>0)) {
    system_detected=false;
  } else {
    String portName = Serial.list()[0];
    myPort = new Serial(this, portName, baudrate);    
    system_detected=true;
  }
}
////////////////////////////////////

//////////////////////////////
// SERIAL EVENTS MANAGEMENT //
//////////////////////////////
void serialEvent(Serial p) { 
  String data = p.readStringUntil('\n'); 
  if (data != null) {
    println(data);
    at_least_1_read = true;
    //Do whatever you want with read data
    if(test_running){
      try {
        String[] parse = data.split(":");
        load = Float.parseFloat(parse[0])+0.0;
        angle = Float.parseFloat(parse[1])+0.0;
        time = Float.parseFloat(parse[2])+0.0-timeOffset;
        mm = angle*angle2mm;
        //Excel likes commas instead of points in numbers
        String str_load = String.valueOf(truncate(load)); //load in tons
        String str_mm = String.valueOf(truncate(mm)); //deformation in mm
        String str_time = String.valueOf(truncate(time)); //time in seconds
        str_load = str_load.replace('.',',');
        str_mm = str_mm.replace('.', ',');
        str_time = str_time.replace('.',',');
        outputFile.println(str_load+" "+str_mm+" "+str_time);
        //str_1st_msg = (angle>lastAngle) ? "Subiendo..." : "Bajando..."; No contempla igualdad
        if(angle>lastAngle) str_1st_msg = "Bajando...";
        else if(angle<lastAngle) str_2nd_msg = "Subiendo...";
        str_2nd_msg = "deformacion_tiempo total: " + str_mm + " mm.\n"+
                      "Carga: " + load*1000 + " kg.";
        if (test_running) {
          carga_deformacion.add(mm, load*1000);
          carga_tiempo.add(time, load);
          deformacion_tiempo.add(time, mm);
        }
        lastAngle = angle;
      }
      catch(Exception e) {
        println("Error while reading data @ "+millis());
      }
    }
  }
} 
//////////////////////////////////////////////////

////////////////////////////
// TRUNCATE TO 2 DECIMALS //
////////////////////////////
float truncate( float x ) {
  return round( x * 100.0f ) / 100.0f;
}

///////////////////////////
// CREATE MESSAGE POP UP //
///////////////////////////
public void MsgBox( String Msg, String Title ) {
  javax.swing.JOptionPane.showMessageDialog ( null, 
    Msg, 
    Title, 
    javax.swing.JOptionPane.INFORMATION_MESSAGE  
    );
}
//////////////////////////////////////////////////