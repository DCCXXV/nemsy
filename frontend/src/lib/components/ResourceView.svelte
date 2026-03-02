<script lang="ts">
	import { PUBLIC_API_BASE_URL } from '$env/static/public';
	import type { Resource } from '$lib/types';
	import { onMount } from 'svelte';
	import { Dialog } from 'bits-ui';
	import CircleNotchIcon from 'phosphor-svelte/lib/CircleNotchIcon';
	import ArrowLeftIcon from 'phosphor-svelte/lib/ArrowLeftIcon';
	import ArrowRightIcon from 'phosphor-svelte/lib/ArrowRightIcon';
	import MagnifyingGlassPlusIcon from 'phosphor-svelte/lib/MagnifyingGlassPlusIcon';
	import MagnifyingGlassMinusIcon from 'phosphor-svelte/lib/MagnifyingGlassMinusIcon';
	import XIcon from 'phosphor-svelte/lib/XIcon';
	import DownloadSimpleIcon from 'phosphor-svelte/lib/DownloadSimpleIcon';

	let { resource }: { resource: Resource } = $props();

	function getExt(r: Resource): string {
		if (!r.files?.length) return '';
		const name = r.files[0].fileName;
		const dot = name.lastIndexOf('.');
		return dot >= 0 ? name.slice(dot + 1).toLowerCase() : '';
	}

	const ext = $derived(getExt(resource));
	const isImage = $derived(['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext));
	const isPdf = $derived(ext === 'pdf');
	const fileUrl = $derived(
		resource.files?.length
			? `${PUBLIC_API_BASE_URL}/api/resources/${resource.id}/files/${resource.files[0].id}/download`
			: ''
	);

	let canvas = $state<HTMLCanvasElement | undefined>(undefined);
	let pdfDoc: any = $state(null);
	let currentPage = $state(1);
	let totalPages = $state(0);
	let pdfLoading = $state(true);
	let pdfError = $state(false);
	let pdfScale = $state(1.5);
	let rendering = $state(false);

	async function renderPage(num: number) {
		if (!pdfDoc || !canvas || rendering) return;
		rendering = true;
		try {
			const page = await pdfDoc.getPage(num);
			const viewport = page.getViewport({ scale: pdfScale });
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

	async function pdfZoomIn() {
		pdfScale = Math.min(pdfScale + 0.25, 4);
		await renderPage(currentPage);
	}

	async function pdfZoomOut() {
		pdfScale = Math.max(pdfScale - 0.25, 0.5);
		await renderPage(currentPage);
	}

	let imgZoom = $state(100);
	let imgLoaded = $state(false);

	onMount(async () => {
		if (!isPdf || !fileUrl) return;

		const pdfjsLib = await import('pdfjs-dist');
		pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
			'pdfjs-dist/build/pdf.worker.min.mjs',
			import.meta.url
		).href;

		try {
			const res = await fetch(fileUrl, { credentials: 'include' });
			if (!res.ok) throw new Error(`HTTP ${res.status}`);
			const data = new Uint8Array(await res.arrayBuffer());
			pdfDoc = await pdfjsLib.getDocument({ data }).promise;
			totalPages = pdfDoc.numPages;
			await renderPage(1);
			pdfLoading = false;
		} catch (e) {
			console.error('PDF load error:', e);
			pdfLoading = false;
			pdfError = true;
		}
	});
</script>

<div class="flex h-full overflow-hidden">
	<div class="flex-1 flex flex-col overflow-hidden border-r border-zinc-300 bg-zinc-100">
		{#if isPdf}
			<div class="flex-1 overflow-auto p-4 relative">
				{#if pdfLoading && !pdfError}
					<div class="absolute inset-0 flex items-center justify-center">
						<CircleNotchIcon class="size-8 text-zinc-400 animate-spin" />
					</div>
				{/if}
				{#if pdfError}
					<div class="flex items-center text-red-400 text-sm">Error al cargar el PDF</div>
				{/if}
				<canvas
					bind:this={canvas}
					class="mx-auto shadow-md {pdfLoading || pdfError ? 'hidden' : ''}"
				></canvas>
				{#if !pdfLoading && !pdfError}
					<div class="sticky bottom-2 flex justify-center pointer-events-none mt-4">
						<div
							class="pointer-events-auto flex items-center gap-1 px-3 py-1.5 bg-zinc-100 border border-zinc-300 text-zinc-700 shadow-sm"
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
							<button
								onclick={pdfZoomOut}
								class="p-1 rounded-none hover:bg-zinc-200 cursor-pointer"
							>
								<MagnifyingGlassMinusIcon class="size-4" />
							</button>
							<span class="text-sm tabular-nums w-10 text-center"
								>{Math.round(pdfScale * 100)}%</span
							>
							<button onclick={pdfZoomIn} class="p-1 rounded-none hover:bg-zinc-200 cursor-pointer">
								<MagnifyingGlassPlusIcon class="size-4" />
							</button>
						</div>
					</div>
				{/if}
			</div>
		{:else if isImage}
			<div class="flex-1 overflow-auto p-4 relative">
				<img
					src={fileUrl}
					alt="preview"
					style="width: {imgZoom}%; max-width: none; display: block; margin: 0 auto;"
					referrerpolicy="no-referrer"
					onload={() => (imgLoaded = true)}
				/>
				{#if imgLoaded}
					<div class="sticky bottom-2 flex justify-center pointer-events-none mt-4">
						<div
							class="pointer-events-auto flex items-center gap-1 px-3 py-1.5 bg-zinc-100 border border-zinc-300 text-zinc-700 shadow-sm"
						>
							<button
								onclick={() => (imgZoom = Math.max(imgZoom - 25, 25))}
								class="p-1 rounded-none hover:bg-zinc-200 cursor-pointer"
							>
								<MagnifyingGlassMinusIcon class="size-4" />
							</button>
							<span class="text-sm tabular-nums w-10 text-center">{imgZoom}%</span>
							<button
								onclick={() => (imgZoom = Math.min(imgZoom + 25, 400))}
								class="p-1 rounded-none hover:bg-zinc-200 cursor-pointer"
							>
								<MagnifyingGlassPlusIcon class="size-4" />
							</button>
							<div class="w-px h-4 bg-zinc-300 mx-1 shrink-0"></div>
							<button
								onclick={() => (imgZoom = 100)}
								class="text-sm px-2 py-1 rounded-none hover:bg-zinc-200 cursor-pointer"
							>
								Reset
							</button>
						</div>
					</div>
				{/if}
			</div>
		{:else}
			<div class="flex-1 flex items-center justify-center text-zinc-400 text-sm">
				Sin previsualización
			</div>
		{/if}
	</div>

	<div class="w-72 shrink-0 relative flex flex-col overflow-y-auto p-2 gap-4 bg-zinc-50">
		<Dialog.Close
			class="absolute top-2 right-2 p-1.5 text-red-600 bg-red-100 hover:text-red-700 hover:bg-red-200 cursor-pointer"
		>
			<XIcon class="size-4" />
		</Dialog.Close>
		<div class="flex flex-col gap-0.5 min-w-0">
			<h2 class="text-xl text-zinc-900 leading-snug">{resource.title}</h2>
			<span class="text-sm text-zinc-500">@{resource.owner?.email?.split('@')[0]}</span>
		</div>
		{#if resource.description}
			<p class="text-sm text-zinc-700 leading-relaxed">{resource.description}</p>
		{/if}
		<a href="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/download" class="mt-auto">
			<div
				class="bg-blue-200 border border-blue-100 hover:bg-blue-100 text-blue-900 px-3 py-2 flex items-center cursor-pointer text-sm rounded-none"
			>
				<DownloadSimpleIcon class="size-4 mr-1" />Descargar
			</div>
		</a>
	</div>
</div>
