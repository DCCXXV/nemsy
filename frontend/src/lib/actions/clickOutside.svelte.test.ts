import { describe, it, expect } from 'vitest';
import { clickOutside } from './clickOutside';

describe('clickOutside', () => {
	it('dispatches outclick when clicking outside the node', () => {
		const node = document.createElement('div');
		const outside = document.createElement('div');
		document.body.appendChild(node);
		document.body.appendChild(outside);

		let fired = false;
		node.addEventListener('outclick', () => {
			fired = true;
		});

		const action = clickOutside(node);
		outside.click();

		expect(fired).toBe(true);

		action.destroy!();
		node.remove();
		outside.remove();
	});

	it('does not dispatch outclick when clicking inside the node', () => {
		const node = document.createElement('div');
		const child = document.createElement('span');
		node.appendChild(child);
		document.body.appendChild(node);

		let fired = false;
		node.addEventListener('outclick', () => {
			fired = true;
		});

		const action = clickOutside(node);
		child.click();

		expect(fired).toBe(false);

		action.destroy!();
		node.remove();
	});

	it('stops listening after destroy', () => {
		const node = document.createElement('div');
		const outside = document.createElement('div');
		document.body.appendChild(node);
		document.body.appendChild(outside);

		let count = 0;
		node.addEventListener('outclick', () => {
			count++;
		});

		const action = clickOutside(node);
		outside.click();
		expect(count).toBe(1);

		action.destroy!();
		outside.click();
		expect(count).toBe(1);

		node.remove();
		outside.remove();
	});
});
