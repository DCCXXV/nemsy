<script lang="ts">
	import { onMount } from 'svelte';
	import CircleNotchIcon from 'phosphor-svelte/lib/CircleNotchIcon';

	let { url }: { url: string } = $props();

	let html = $state('');
	let loading = $state(true);
	let error = $state(false);

	onMount(async () => {
		try {
			const res = await fetch(url, { credentials: 'include' });
			if (!res.ok) throw new Error(`HTTP ${res.status}`);
			const text = await res.text();
			const { marked } = await import('marked');
			const DOMPurify = (await import('dompurify')).default;
			html = DOMPurify.sanitize(marked.parse(text) as string);
			loading = false;
		} catch (e) {
			console.error('Markdown load error:', e);
			loading = false;
			error = true;
		}
	});
</script>

<div class="flex-1 overflow-auto p-4">
	{#if loading && !error}
		<div class="flex items-center justify-center h-full">
			<CircleNotchIcon class="size-8 text-zinc-400 animate-spin" />
		</div>
	{:else if error}
		<div class="flex items-center text-red-400 text-sm">Error al cargar el archivo</div>
	{:else}
		<div class="prose prose-zinc max-w-none text-sm">
			{@html html}
		</div>
	{/if}
</div>
