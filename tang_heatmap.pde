import processing.serial.*;
Serial myPort;
PrintWriter file;

String com_port = "";
int buf_count = 0;
int rx_index = 0;
int calibration_flg = 0;
int[] rx_data = new int[2];
float[] data = new float [64];
float[] ideals = {1,1536,3072};
float[][] thre = new float [3][64];
float[][] coef = new float [3][64];

String today = nf(year(),2)+"_"+nf(month(),2)+"_"+nf(day(),2)+"_"+nf(hour(),2) +""+ nf(minute(),2);
String[] string_calibration = {"calibration ON  (switch 'e')","calibration OFF  (switch 'e')"};
String[] string_writing = {"","writing..."};

int export_flg = 0;
int exporting = 0;
int mil_begin = 0;
int mil_now = 0;
int timestamp = 0;

void setup() {
    colorMode(HSB, 4096*100/68, 100, 100);
    size(600,700);
    background(0,0,255);
    noStroke();
    textAlign(CENTER,CENTER);
    textSize(20);
    frameRate(60);

    String[] read_csv = loadStrings("./tang_setting.csv");
    for(int i = 0; i < 4; i++){
        String[] cash = split(read_csv[i],',');
        if(i == 0) com_port = cash[0];
        else{
            for(int j = 0; j < 64; j++){
                thre[i-1][j] = float(cash[j]);
                if(i == 1) coef[0][j] = ideals[0]/thre[0][j];
                else coef[i-1][j] = (ideals[i-1]-ideals[i-2])/(thre[i-1][j]-thre[i-2][j]);
            }
        }
    }
    myPort = new Serial(this, com_port, 115200);
}

void serialEvent(Serial myPort) {
    if(true){
        if (myPort.available() > 0) {
            int rx_buf = myPort.read();
            if ((buf_count == 0) && ((rx_buf & 0x80) == 0x80)) {
                rx_index = rx_buf & 0x7F;
                buf_count = 1;
                if(rx_index >= 64){
                    buf_count = 0;
                }
            }else if (buf_count == 1) {
                rx_data[0] = rx_buf;
                buf_count = 2;
            }else if (buf_count == 2) {
                rx_data[1] = rx_buf;
                int buf_val = (rx_data[0] << 8)|(rx_data[1]);
                data[rx_index] = (float)((buf_val&7) | ((buf_val&112) >> 1) | ((buf_val&1792) >> 2) | ((buf_val&28672) >> 3));
                if(calibration_flg == 0) data[rx_index] = calib_Ch1(rx_index, data[rx_index]);
                buf_count = 0;
            }
        }
    }
}

void draw() {
    background(0,0,255);
    heatmap(300,300);
    context(300,650);
    export_data();
}

//ハロー、関数さんよ。
void heatmap(int x, int y){
    noStroke();
    pushMatrix();
    translate(x,y);
    for(int index = 0; index < 64; index++){
        fill((4096-data[index]), 100, 100);
        rect(where_x(index+1),where_y(index+1),50,50);  
    }
    popMatrix();
}

float calib_Ch1(int index, float rare_val){
    float calib_data = 0.00;
    if(rare_val < thre[0][index]) calib_data = coef[0][index]*rare_val;
    else if(rare_val < thre[1][index]) calib_data = coef[0][index]*thre[0][index] + coef[1][index]*(rare_val-thre[0][index]);
    else calib_data = coef[0][index]*thre[0][index] + coef[1][index]*(thre[1][index]-thre[0][index]) + coef[2][index]*(rare_val-thre[1][index]);
    if(calib_data > 3000) calib_data = 3000;
    return calib_data;
}

void context(int x, int y){
    stroke(0);
    fill(0);

    text(string_calibration[calibration_flg], x-100, y-20);
    text(string_writing[export_flg], x+100, y-20);
    text("w: write data  /  q: save and exit", x, y+20);
}

int where_x(int i){
    int x = 0;
    if(i <= 7){
        if(i%2 == 1) x = -50;
        else x = -100;
    }else if(i <= 16){
        if(i%3 == 1) x = -50;
        else if(i%3 == 0) x = -100;
        else x = -150;
    }else if(i <= 32){
        if(i%4 == 0) x = -50;
        else if(i%4 == 3) x = -100;
        else if(i%4 == 2) x = -150;
        else x = -200;
    }else if(i == 33){
        x = 0;
    }else if(i <= 39){
        if(i%2 == 0) x = 0;
        else x = 50; 
    }else if(i <= 48){
        if(i%3 == 1) x = 0;
        else if(i%3 == 2) x = 50;
        else x = 100;
    }else if(i <= 64){
        if(i%4 == 1) x = 0;
        else if(i%4 == 2) x = 50;
        else if(i%4 == 3) x = 100;
        else x = 150;
    }
    return x;
}

int where_y(int i){
    int y = 0;
    if((i==1)||(i==33)) y = -275;
    else if(((i>=2)&&(i<=3))||((i>=34)&&(i<=35))) y = -225;
    else if(((i>=4)&&(i<=5))||((i>=36)&&(i<=37))) y = -175;
    else if(((i>=6)&&(i<=7))||((i>=38)&&(i<=39))) y = -125;
    else if(((i>=8)&&(i<=10))||((i>=40)&&(i<=42))) y = -75;
    else if(((i>=11)&&(i<=13))||((i>=43)&&(i<=45))) y = -25;
    else if(((i>=14)&&(i<=16))||((i>=46)&&(i<=48))) y = 25;
    else if(((i>=17)&&(i<=20))||((i>=49)&&(i<=52))) y = 75;
    else if(((i>=21)&&(i<=24))||((i>=53)&&(i<=56))) y = 125;
    else if(((i>=25)&&(i<=28))||((i>=57)&&(i<=60))) y = 175;
    else if(((i>=29)&&(i<=32))||((i>=61)&&(i<=64))) y = 225;
    return y;
}

void export_data(){
    if(export_flg == 1){
        mil_now = millis();
        if(mil_begin == 0) mil_begin = mil_now;
        exporting = 1;
        csv_write();
        exporting = 0;
    }
}

void csv_write(){
    timestamp = mil_now - mil_begin;
    file.print(timestamp+",");
    for(int i = 0; i < 63; i++) file.print(int(data[i])+",");
    file.println(int(data[63]));
}

void keyPressed(){
    if(key == 'w'){
        file = createWriter("./tang_data/" + today + ".csv");
        file.print("msec,");
        for(int i = 0; i < 63; i++) file.print("Ch"+(i+1)+",");
        file.println("Ch"+64);
        export_flg = 1;
    }else if(key == 'e'){
        if(calibration_flg == 0) calibration_flg = 1;
        else calibration_flg = 0;
    }else if(key == 'q'){
        if((export_flg == 1)&&(exporting == 0)){
            file.flush();
            file.close();
        }
        exit();
    }
}
