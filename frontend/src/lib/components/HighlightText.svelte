<script>
	let { text, query } = $props();

	const parts = $derived(
		(() => {
			const trimmed = query?.trim();
			if (!trimmed) {
				return [{ text, highlight: false }];
			}

			const lowerText = text.toLowerCase();
			const lowerQuery = trimmed.toLowerCase();

			const index = lowerText.indexOf(lowerQuery);

			if (index === -1) {
				return [{ text: text, highlight: false }];
			}

			return [
				{ text: text.slice(0, index), highlight: false },
				{ text: text.slice(index, index + trimmed.length), highlight: true },
				{ text: text.slice(index + trimmed.length), highlight: false }
			];
		})()
	);
</script>

{#each parts as part, i (i)}
	{#if part.highlight}
		<mark class="bg-amber-200 text-amber-900">{part.text}</mark>
	{:else}
		{part.text}
	{/if}
{/each}
