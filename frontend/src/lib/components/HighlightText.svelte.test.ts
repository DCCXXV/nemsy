import { describe, it, expect } from 'vitest';
import { render } from 'vitest-browser-svelte';
import { page } from '@vitest/browser/context';
import HighlightText from './HighlightText.svelte';

describe('HighlightText', () => {
	it('highlights the matching substring', async () => {
		render(HighlightText, { text: 'Álgebra Lineal', query: 'lineal' });

		const mark = page.getByRole('mark');
		await expect.element(mark).toHaveTextContent('Lineal');
	});

	it('renders plain text when there is no match', async () => {
		const { container } = render(HighlightText, { text: 'Cálculo', query: 'física' });

		expect(container.querySelectorAll('mark').length).toBe(0);
		expect(container.textContent).toBe('Cálculo');
	});

	it('renders plain text when query is empty', async () => {
		const { container } = render(HighlightText, { text: 'Cálculo', query: '' });

		expect(container.querySelectorAll('mark').length).toBe(0);
		expect(container.textContent).toBe('Cálculo');
	});
});
