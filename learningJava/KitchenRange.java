/* A real-world object translated into a software class
as part of Java exercise*/

interface Range {
	void changeBurners(int[] newValue);
	
	void turnOvenOn();
	
	void turnOvenOff();
	
	void setOvenTemp(int newValue);
	
	void setOvenTimer(int hours, int minutes);
}

class KitchenRange implements Range{
	// burner settings 0-10
	int[] burners = {0,0,0,0};
	boolean oven = false;
	int oventemp = 23; //Celsius
	
	public void changeBurners(int[] newValue){
		burners = newValue;
	}
	
	public void turnOvenOn (){
		oven = true;
	}
	
	public void turnOvenOff(){
		oven = false;
		oventemp = 23;
	}
	
	public void setOvenTimer(int hours, int min){
		//do nothing yet
	}
	
	public void setOvenTemp (int newValue){
		if (oven == true){
			oventemp = newValue;
		}else{
			System.out.println("Turn oven on, prior to setting temperature.");
		}
	}
	
	void printStates() {
         System.out.println("burners:" +
             burners + " oven on:" + 
             oven + " oven temperature:" + oventemp);
    }
	
}