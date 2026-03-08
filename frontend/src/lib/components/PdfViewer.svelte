<script lang="ts">
	import { onMount } from 'svelte';
	import CircleNotchIcon from 'phosphor-svelte/lib/CircleNotchIcon';
	import ArrowLeftIcon from 'phosphor-svelte/lib/ArrowLeftIcon';
	import ArrowRightIcon from 'phosphor-svelte/lib/ArrowRightIcon';
	import MagnifyingGlassPlusIcon from 'phosphor-svelte/lib/MagnifyingGlassPlusIcon';
	import MagnifyingGlassMinusIcon from 'phosphor-svelte/lib/MagnifyingGlassMinusIcon';

	let {
		url,
		thumbnail = false
	}: {
		url: string;
		thumbnail?: boolean;
	} = $props();

	let canvas = $state<HTMLCanvasElement | undefined>(undefined);
	let pdfDoc: any = $state(null);
	let currentPage = $state(1);
	let totalPages = $state(0);
	let loading = $state(true);
	let error = $state(false);
	let scale = $state(1.5);
	let rendering = $state(false);

	async function renderPage(num: number) {
		if (!pdfDoc || !canvas || rendering) return;
		rendering = true;
		try {
			const page = await pdfDoc.getPage(num);
			const viewport = page.getViewport({ scale });
			canvas.width = viewport.width;
			canvas.height = viewport.height;
			const ctx = canvas.getContext('2d')!;
			await page.render({ canvasContext: ctx, viewport, canvas }).promise;
		} finally {
			rendering = false;
		}
	}

	async function prevPage() {
		if (currentPage <= 1 || rendering) return;
		currentPage--;
		await renderPage(currentPage);
	}

	async function nextPage() {
		if (currentPage >= totalPages || rendering) return;
		currentPage++;
		await renderPage(currentPage);
	}

	async function zoomIn() {
		scale = Math.min(scale + 0.25, 4);
		await renderPage(currentPage);
	}

	async function zoomOut() {
		scale = Math.max(scale - 0.25, 0.5);
		await renderPage(currentPage);
	}

	async function onWheel(e: WheelEvent) {
		if (!e.ctrlKey) return;
		e.preventDefault();
		if (e.deltaY < 0) await zoomIn();
		else await zoomOut();
	}

	onMount(async () => {
		const pdfjsLib = await import('pdfjs-dist');
		pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
			'pdfjs-dist/build/pdf.worker.min.mjs',
			import.meta.url
		).href;

		try {
			const res = await fetch(url, { credentials: 'include' });
			if (!res.ok) throw new Error(`HTTP ${res.status}`);
			const data = new Uint8Array(await res.arrayBuffer());
			pdfDoc = await pdfjsLib.getDocument({ data }).promise;
			totalPages = pdfDoc.numPages;
			await renderPage(1);
			loading = false;
		} catch (e) {
			console.error('PDF load error:', e);
			loading = false;
			error = true;
		}
	});
</script>

{#if thumbnail}
	<div class="relative w-full max-h-100 overflow-hidden {loading && !error ? 'aspect-3/4' : ''}">
		{#if loading && !error}
			<div class="absolute inset-0 flex items-center justify-center">
				<CircleNotchIcon class="size-8 text-zinc-400 animate-spin" />
			</div>
		{/if}
		{#if error}
			<div class="h-24 flex items-center justify-center text-red-300">
				Error al cargar la previsualización
			</div>
		{/if}
		<canvas bind:this={canvas} class="w-full {loading || error ? 'hidden' : ''}"></canvas>
	</div>
{:else}
	<div class="flex-1 overflow-auto p-4 relative" onwheel={onWheel}>
		{#if loading && !error}
			<div class="absolute inset-0 flex items-center justify-center">
				<CircleNotchIcon class="size-8 text-zinc-400 animate-spin" />
			</div>
		{/if}
		{#if error}
			<div class="flex items-center text-red-400 text-sm">Error al cargar el PDF</div>
		{/if}
		<canvas
			bind:this={canvas}
			class="mx-auto border border-zinc-300 {loading || error ? 'hidden' : ''}"
		></canvas>
		{#if !loading && !error}
			<div class="sticky bottom-2 flex justify-center pointer-events-none mt-4">
				<div
					class="pointer-events-auto flex items-center gap-1 px-3 py-1.5 bg-zinc-50 border border-zinc-300 text-zinc-700 shadow-sm"
				>
					<button
						onclick={prevPage}
						disabled={currentPage <= 1 || rendering}
						class="p-1 rounded-none disabled:opacity-30 hover:bg-zinc-200 cursor-pointer"
					>
						<ArrowLeftIcon class="size-4" />
					</button>
					<span class="text-sm tabular-nums px-1">{currentPage} / {totalPages}</span>
					<button
						onclick={nextPage}
						disabled={currentPage >= totalPages || rendering}
						class="p-1 rounded-none disabled:opacity-30 hover:bg-zinc-200 cursor-pointer"
					>
						<ArrowRightIcon class="size-4" />
					</button>
					<div class="w-px h-4 bg-zinc-300 mx-1 shrink-0"></div>
					<button onclick={zoomOut} class="p-1 rounded-none hover:bg-zinc-200 cursor-pointer">
						<MagnifyingGlassMinusIcon class="size-4" />
					</button>
					<span class="text-sm tabular-nums w-10 text-center">{Math.round(scale * 100)}%</span>
					<button onclick={zoomIn} class="p-1 rounded-none hover:bg-zinc-200 cursor-pointer">
						<MagnifyingGlassPlusIcon class="size-4" />
					</button>
				</div>
			</div>
		{/if}
	</div>
{/if}
