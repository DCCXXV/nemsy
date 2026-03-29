<script lang="ts">
	import { PUBLIC_API_BASE_URL } from '$env/static/public';
	import type { Resource } from '$lib/types';
	import { Dialog } from 'bits-ui';
	import MagnifyingGlassIcon from 'phosphor-svelte/lib/MagnifyingGlassIcon';
	import SpinnerIcon from 'phosphor-svelte/lib/SpinnerIcon';
	import DownloadSimpleIcon from 'phosphor-svelte/lib/DownloadSimpleIcon';
	import FolderIcon from 'phosphor-svelte/lib/FolderIcon';
	import FilePdfIcon from 'phosphor-svelte/lib/FilePdfIcon';
	import FileIcon from 'phosphor-svelte/lib/FileIcon';
	import ImageIcon from 'phosphor-svelte/lib/ImageIcon';
	import MarkdownLogoIcon from 'phosphor-svelte/lib/MarkdownLogoIcon';
	import QuestionIcon from 'phosphor-svelte/lib/QuestionIcon';
	import ResourceView from '$lib/components/ResourceView.svelte';

	function getFirstFileExt(resource: Resource): string {
		if (!resource.files?.length) return '';
		const name = resource.files[0].fileName;
		const dot = name.lastIndexOf('.');
		return dot >= 0 ? name.slice(dot + 1).toLowerCase() : '';
	}

	function isImage(ext: string) {
		return ['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext);
	}
	function isPdf(ext: string) {
		return ext === 'pdf';
	}
	function isMarkdown(ext: string) {
		return ext === 'md' || ext === 'markdown';
	}

	let query = $state('');
	let results = $state<Resource[]>([]);
	let loading = $state(false);
	let searched = $state(false);
	let debounceTimer: ReturnType<typeof setTimeout>;

	async function search() {
		const q = query.trim();
		if (!q) {
			results = [];
			searched = false;
			return;
		}

		loading = true;
		searched = true;

		try {
			const res = await fetch(
				`${PUBLIC_API_BASE_URL}/api/resources/search?q=${encodeURIComponent(q)}`,
				{ credentials: 'include' }
			);
			if (res.ok) {
				results = await res.json();
			}
		} catch (err) {
			console.error('Search error:', err);
		} finally {
			loading = false;
		}
	}

	function onInput() {
		clearTimeout(debounceTimer);
		debounceTimer = setTimeout(search, 300);
	}
</script>

<div class="bg-zinc-100 min-h-screen flex flex-col items-center px-4 relative overflow-hidden">
	<div class="w-full max-w-4xl mt-24 relative z-10">
		<div class="flex items-center justify-center gap-6 md:gap-10">
			<img
				src="/favicon.svg"
				alt=""
				class="hidden md:block size-30 opacity-60 pointer-events-none shrink-0"
			/>

			<div class="w-full max-w-2xl">
				<h1 class="text-3xl text-zinc-600 text-center mb-4">Búsqueda Global</h1>
				<div class="relative">
					<MagnifyingGlassIcon
						class="absolute left-3 top-1/2 -translate-y-1/2 size-5 text-zinc-400"
					/>
					<input
						type="text"
						bind:value={query}
						oninput={onInput}
						placeholder="Buscar recursos de toda la plataforma..."
						class="w-full bg-zinc-50 border border-zinc-300 rounded-none py-3 pl-10 pr-4 text-zinc-700 focus:outline-none focus:border-indigo-300 focus:ring-0"
					/>
				</div>
			</div>

			<img
				src="/favicon.svg"
				alt=""
				class="hidden md:block size-30 opacity-60 pointer-events-none shrink-0 -scale-x-100"
			/>
		</div>

		{#if loading}
			<div class="flex justify-center mt-12">
				<SpinnerIcon class="size-10 text-zinc-400 animate-spin" />
			</div>
		{:else if searched && results.length === 0}
			<p class="text-zinc-500 text-center mt-12">No se encontraron resultados.</p>
		{:else if results.length > 0}
			<div class="bg-zinc-50 mt-6">
				{#each results as resource (resource.id)}
					{@const ext = getFirstFileExt(resource)}
					<Dialog.Root>
						<Dialog.Trigger
							class="border-b last:border-b-0 p-2 border-zinc-200 hover:bg-zinc-100 w-full text-left cursor-pointer flex gap-3"
						>
							{#if !resource.files?.length}
								<div
									class="w-20 self-stretch border border-zinc-300 bg-zinc-200 flex items-center justify-center shrink-0"
								>
									<FileIcon weight="fill" class="size-12 text-zinc-400" />
								</div>
							{:else if resource.files.length > 1}
								<div
									class="w-20 self-stretch border border-yellow-400 bg-yellow-400 flex items-center justify-center shrink-0"
								>
									<FolderIcon weight="fill" class="size-12 text-zinc-50" />
								</div>
							{:else if isPdf(ext)}
								<div
									class="w-20 self-stretch border border-red-400 bg-red-400 flex items-center justify-center shrink-0"
								>
									<FilePdfIcon weight="fill" class="size-12 text-zinc-50" />
								</div>
							{:else if isImage(ext)}
								<div
									class="w-20 self-stretch border border-lime-400 bg-lime-400 flex items-center justify-center shrink-0"
								>
									<ImageIcon weight="fill" class="size-12 text-zinc-50" />
								</div>
							{:else if isMarkdown(ext)}
								<div
									class="w-20 self-stretch border border-blue-400 bg-blue-400 flex items-center justify-center shrink-0"
								>
									<MarkdownLogoIcon weight="fill" class="size-12 text-zinc-50" />
								</div>
							{:else}
								<div
									class="w-20 self-stretch border border-violet-400 bg-violet-400 flex items-center justify-center shrink-0"
								>
									<QuestionIcon weight="fill" class="size-12 text-zinc-50" />
								</div>
							{/if}
							<div class="flex flex-col flex-1 justify-between py-1">
								<div>
									{#if resource.university || resource.study}
										<p class="text-zinc-500 mb-1">
											{resource.university?.name}{#if resource.university && resource.study}
												<span class="mx-1">-</span>
											{/if}{resource.study?.name}
										</p>
									{/if}
									<h2 class="text-lg">{resource.title}</h2>
									<span class="text-sm text-zinc-500">@{resource.owner?.username}</span>
								</div>
								<div class="flex justify-end gap-2">
									<span class="flex items-center border border-blue-300 text-sm">
										<span class="bg-zinc-50 text-blue-900 px-1.5 py-0.5 flex items-center gap-1">
											{resource.downloadCount}<DownloadSimpleIcon class="size-4" />
										</span>
										<span class="bg-blue-200 text-blue-900 px-2 py-0.5"> Descargar </span>
									</span>
								</div>
							</div>
						</Dialog.Trigger>
						<Dialog.Portal>
							<Dialog.Overlay class="fixed inset-0 z-50 bg-black/30" />
							<Dialog.Content
								class="bg-zinc-50 border-zinc-300 outline-hidden fixed left-[50%] top-[50%] z-50 w-full max-w-[calc(100%-1rem)] md:max-w-[calc(100%-8rem)] h-[calc(100svh-1rem)] md:h-[calc(100svh-4rem)] translate-x-[-50%] translate-y-[-50%] border overflow-hidden"
							>
								<ResourceView {resource} />
							</Dialog.Content>
						</Dialog.Portal>
					</Dialog.Root>
				{/each}
			</div>
		{/if}
	</div>
</div>
