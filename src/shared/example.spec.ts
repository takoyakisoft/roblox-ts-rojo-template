/// <reference types="@rbxts/testez/globals" />

import { add, subtract } from "./example";

export = () => {
	describe("Example Module", () => {
		it("should add two numbers correctly", () => {
			expect(add(2, 3)).to.equal(5);
			expect(add(-1, 1)).to.equal(0);
		});

		it("should subtract two numbers correctly", () => {
			expect(subtract(5, 2)).to.equal(3);
			expect(subtract(1, 3)).to.equal(-2);
		});
	});
};
