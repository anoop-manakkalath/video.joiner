import java.io {
	File,
	BufferedReader,
	InputStreamReader
}
import java.lang {
	Process,
	System,
	Runtime,
	Runnable,
	Thread
}
import java.util.concurrent.locks {
	LockSupport
}

import javafx.application {
	Application
}
import javafx.event {
	ActionEvent,
	EventHandler
}
import javafx.geometry {
	Pos,
	Insets
}
import javafx.scene {
	Scene
}
import javafx.scene.control {
	Button,
	FxLabel=Label,
	TextField,
	TextArea
}
import javafx.scene.input {
	MouseEvent
}
import javafx.scene.layout {
	GridPane,
	HBox
}
import javafx.stage {
	Stage,
	FileChooser
}

shared class Converter() extends Application() {
	
	value txtVideo = TextField();
	value txtAudio = TextField();
	
	value btnVideo = Button("^");
	value btnAudio = Button("^");
	
	value txtConsole = TextArea();
	
	object videoAction satisfies EventHandler<MouseEvent> {
		shared actual void handle(MouseEvent event) {
			value chooser = FileChooser();
			chooser.initialDirectory = File(System.getProperty("user.home")).absoluteFile;
			value file = chooser.showOpenDialog(null);
			if (exists file) {
				txtVideo.text = file.absolutePath;
			}
		}
	}
	
	object audioAction satisfies EventHandler<MouseEvent> {
		shared actual void handle(MouseEvent event) {
			value chooser = FileChooser();
			chooser.initialDirectory = File(System.getProperty("user.home")).absoluteFile;
			value file = chooser.showOpenDialog(null);
			if (exists file) {
				txtAudio.text = file.absolutePath;
			}
		}
	}
	
	object eventAction satisfies EventHandler<ActionEvent> {
		shared actual void handle(ActionEvent event) {
			variable String outFile;
			variable String cmd = "ffmpeg -i ^^video -i ^^audio -codec copy -shortest ^^output";
			value os = System.getProperty("os.name");
			
			if (os.startsWith("Windows")) {
				outFile = "\"" + findFileName(txtVideo.text) + "_1" + findFileExt(txtVideo.text) + "\"";
				cmd = cmd.replace("^^video", "\"" + txtVideo.text + "\"")
						.replace("^^audio", "\"" + txtAudio.text + "\"").replace("^^output", outFile);
				
			}
			else {
				String vString = convertToPosixFileName(txtVideo.text);
				String aString = convertToPosixFileName(txtAudio.text);
				outFile = convertToPosixFileName(findFileName(txtVideo.text)) + "_1" + findFileExt(txtVideo.text);
				cmd = cmd.replace("^^video", vString).replace("^^audio", aString).replace("^^output", outFile);
			}
			print("Executing ``cmd``");
			Process proc = Runtime.runtime.exec(cmd);
			
			try (value stdInput = BufferedReader(InputStreamReader(proc.inputStream)),
				value stdError = BufferedReader(InputStreamReader(proc.errorStream))) {
				Thread(PipeStream(stdInput)).start();
				Thread(PipeStream(stdError)).start();
				proc.waitFor();
				LockSupport.parkNanos(10000 ^ 10000);
				value errFlag  = stdError.lines().count() > 0;
				if (!errFlag) {
					txtConsole.appendText("[  OK  ] Successfully multiplexed the streams.\n");
				}
			}
			
			txtVideo.text = "";
			txtAudio.text = "";
		}
		
	}
	
	class PipeStream(BufferedReader stdInput) satisfies Runnable {
		
		shared actual void run() {
			stdInput.lines().forEach((line) =>  txtConsole.appendText(line.string + "\n"));
		}
	}
	
	shared actual void start(Stage primaryStage) {
		value grid = GridPane();
		grid.alignment = Pos.center;
		grid.hgap = 10.0;
		grid.vgap = 10.0;
		grid.padding = Insets(25.0, 25.0, 25.0, 25.0);
		
		btnVideo.onMouseClicked => videoAction;
		btnAudio.onMouseClicked => audioAction;
		
		value lblVideo = FxLabel("Video: ");
		grid.add(lblVideo, 0, 1);
		grid.add(txtVideo, 1, 1);
		grid.add(btnVideo, 2, 1);
		
		value lblAudio = FxLabel("Audio: ");
		grid.add(lblAudio, 0, 2);
		grid.add(txtAudio, 1, 2);
		grid.add(btnAudio, 2, 2);
		
		value btn = Button("Multiplex");
		btn.onAction => eventAction;
		
		value hbBtn = HBox();
		hbBtn.alignment = Pos.bottomRight;
		hbBtn.children.add(btn);
		grid.add(hbBtn, 1, 3);
		
		value lblConsole = FxLabel("Console: ");
		value hbConsole = HBox();
		hbConsole.alignment = Pos.bottomRight;
		hbConsole.children.add(txtConsole);
		grid.add(lblConsole, 0, 4);
		grid.add(hbConsole, 1, 4);
		
		primaryStage.title = "VideoMerger 0.1a7";
		primaryStage.setScene(Scene(grid, 720.0, 360.0));
		primaryStage.resizable = false;
		primaryStage.show();
	}
	
}
