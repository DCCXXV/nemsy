<script lang="ts">
	import PdfViewer from '$lib/components/PdfViewer.svelte';

	let { url }: { url: string } = $props();
</script>

<PdfViewer {url} thumbnail={true} />
