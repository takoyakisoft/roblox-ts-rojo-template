import React, { StrictMode } from "@rbxts/react";
import { createPortal, createRoot } from "@rbxts/react-roblox";

const App = () => (
	<screengui>
		<textlabel
			Size={new UDim2(0, 100, 0, 75)}
			Position={new UDim2(0.5, 0, 0.5, 0)}
			Text={"Hello World!"}
			AnchorPoint={new Vector2(0.5, 0.5)}
		/>
	</screengui>
);

const playerGui = game.GetService("Players").LocalPlayer.WaitForChild("PlayerGui");

const root = createRoot(new Instance("Folder"));

root.render(<StrictMode>{createPortal(<App />, playerGui)}</StrictMode>);
