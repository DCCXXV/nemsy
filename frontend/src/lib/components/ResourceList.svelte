<script lang="ts">
	import { PUBLIC_API_BASE_URL } from '$env/static/public';
	import type { Resource } from '$lib/types';
	import { Dialog } from 'bits-ui';
	import { onMount } from 'svelte';

	import DownloadSimpleIcon from 'phosphor-svelte/lib/DownloadSimpleIcon';
	import FolderIcon from 'phosphor-svelte/lib/FolderIcon';
	import FilePdfIcon from 'phosphor-svelte/lib/FilePdfIcon';
	import FileIcon from 'phosphor-svelte/lib/FileIcon';
	import ImageIcon from 'phosphor-svelte/lib/ImageIcon';
	import MarkdownLogoIcon from 'phosphor-svelte/lib/MarkdownLogoIcon';
	import QuestionIcon from 'phosphor-svelte/lib/QuestionIcon';
	import ImagesIcon from 'phosphor-svelte/lib/ImagesIcon';
	import ClockClockwiseIcon from 'phosphor-svelte/lib/ClockClockwiseIcon';
	import SmileyNervousIcon from 'phosphor-svelte/lib/SmileyNervousIcon';
	import MagnifyingGlassIcon from 'phosphor-svelte/lib/MagnifyingGlassIcon';

	import PdfThumbnail from '$lib/components/PdfThumbnail.svelte';
	import MarkdownViewer from '$lib/components/MarkdownViewer.svelte';
	import ResourceView from '$lib/components/ResourceView.svelte';
	import UserAvatar from '$lib/components/UserAvatar.svelte';

	let {
		resources,
		compactMode: initialCompactMode = false,
		emptyMessage = 'Todavía no hay recursos aquí.',
		emptySubMessage = '',
		showSubject = false
	}: {
		resources: Resource[];
		compactMode?: boolean;
		emptyMessage?: string;
		emptySubMessage?: string;
		showSubject?: boolean;
	} = $props();

	let compactMode = $state(initialCompactMode);
	let query = $state('');

	const filteredResources = $derived(
		query.trim() === ''
			? resources
			: resources.filter(
					(r) =>
						r.title.toLowerCase().includes(query.toLowerCase()) ||
						r.description?.toLowerCase().includes(query.toLowerCase())
				)
	);

	onMount(() => {
		const saved = localStorage.getItem('compactMode');
		if (saved !== null) compactMode = saved === 'true';
	});

	function toggleCompactMode() {
		compactMode = !compactMode;
		localStorage.setItem('compactMode', compactMode.toString());
	}

	function getFirstFileExt(resource: Resource): string {
		if (!resource.files?.length) return '';
		const name = resource.files[0].fileName;
		const dot = name.lastIndexOf('.');
		return dot >= 0 ? name.slice(dot + 1).toLowerCase() : '';
	}

	function isImage(ext: string): boolean {
		return ['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext);
	}

	function isPdf(ext: string): boolean {
		return ext === 'pdf';
	}

	function isMarkdown(ext: string): boolean {
		return ext === 'md' || ext === 'markdown';
	}
</script>

<div class="bg-zinc-100 border-b border-zinc-300 flex items-center py-1 justify-end">
	<div
		class="flex-1 flex items-center gap-1 px-2 text-zinc-500 m-1 border-b border-transparent focus-within:border-zinc-500"
	>
		<MagnifyingGlassIcon class="size-6" />
		<input
			type="text"
			placeholder="Buscar recursos..."
			bind:value={query}
			class="bg-transparent text-sm text-zinc-700 placeholder-zinc-400 outline-none border-none focus:outline-none ring-0 focus:ring-0 w-full"
		/>
	</div>
	<div class="text-zinc-500 bg-zinc-100 border-l border-zinc-300">
		<button class="flex gap-1 items-center justify-center px-2">
			<ClockClockwiseIcon class="size-6" />
			<span class="w-20 text-left">Recientes</span>
		</button>
	</div>
	<div class="text-zinc-500 bg-zinc-100 border-l hover:text-zinc-900 border-zinc-300">
		<button
			class="flex gap-1 items-center justify-center cursor-pointer px-2"
			onclick={toggleCompactMode}
		>
			<ImagesIcon class="size-6" />
			<span class="w-23 text-left">{compactMode ? 'Compacto' : 'Desplegado'}</span>
		</button>
	</div>
</div>

{#if filteredResources.length === 0}
	<div
		class="flex flex-col items-center justify-center py-24 px-6 text-zinc-400 gap-3 border-b border-zinc-300"
	>
		<SmileyNervousIcon weight="thin" class="size-16 text-zinc-400" />
		<p class="text-center text-zinc-500 text-lg">
			{query.trim() ? 'No hay recursos que coincidan con tu búsqueda.' : emptyMessage}
		</p>
		{#if emptySubMessage && !query.trim()}
			<p class="text-zinc-400 text-sm">{emptySubMessage}</p>
		{/if}
	</div>
{:else}
	{#each filteredResources as resource (resource.id)}
		<Dialog.Root>
			<Dialog.Trigger
				class="border-b last:border-b-0 p-2 border-zinc-200 hover:bg-zinc-100 w-full text-left cursor-pointer"
			>
				{#if compactMode}
					{#if showSubject && resource.subject}
						<p class="text-xs font-semibold text-zinc-500 uppercase tracking-wide mb-1">
							{resource.subject.name}
						</p>
					{/if}
					<div class="flex gap-3">
						{#if !resource.files?.length}
							<div
								class="w-20 self-stretch rounded-none border border-zinc-300 bg-zinc-200 flex items-center justify-center"
							>
								<FileIcon weight="fill" class="size-12 text-zinc-400" />
							</div>
						{:else if resource.files.length > 1}
							<div
								class="w-20 self-stretch rounded-none border border-yellow-400 bg-yellow-400 flex items-center justify-center"
							>
								<FolderIcon weight="fill" class="size-12 text-zinc-50" />
							</div>
						{:else if isPdf(getFirstFileExt(resource))}
							<div
								class="w-20 self-stretch rounded-none border border-red-400 bg-red-400 flex items-center justify-center"
							>
								<FilePdfIcon weight="fill" class="size-12 text-zinc-50" />
							</div>
						{:else if isImage(getFirstFileExt(resource))}
							<div
								class="w-20 self-stretch rounded-none border border-lime-400 bg-lime-400 flex items-center justify-center"
							>
								<ImageIcon weight="fill" class="size-12 text-zinc-50" />
							</div>
						{:else if isMarkdown(getFirstFileExt(resource))}
							<div
								class="w-20 self-stretch rounded-none border border-blue-400 bg-blue-400 flex items-center justify-center"
							>
								<MarkdownLogoIcon weight="fill" class="size-12 text-zinc-50" />
							</div>
						{:else}
							<div
								class="w-20 self-stretch rounded-none border border-violet-400 bg-violet-400 flex items-center justify-center"
							>
								<QuestionIcon weight="fill" class="size-12 text-zinc-50" />
							</div>
						{/if}
						<div class="flex flex-col flex-1 justify-between py-1">
							<div>
								<h2 class="text-base">{resource.title}</h2>
								<a
									href="/user/{resource.owner?.username}"
									class="text-sm text-zinc-500 hover:text-zinc-400"
									onclick={(e) => e.stopPropagation()}
								>
									@{resource.owner?.username}
								</a>
							</div>
							<div class="flex justify-end gap-2">
								<a
									href="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/download"
									onclick={(e) => e.stopPropagation()}
								>
									<div
										class="bg-blue-200 border border-blue-100 hover:bg-blue-100 text-blue-900 px-2 py-0.5 flex items-center cursor-pointer text-sm rounded-none"
									>
										<DownloadSimpleIcon class="size-4 mr-1" />Descargar
									</div>
								</a>
							</div>
						</div>
					</div>
				{:else}
					<div class="flex w-full gap-2">
						<div class="flex flex-col gap-2 w-full">
							{#if showSubject && resource.subject}
								<p class="text-xs font-semibold text-zinc-500 uppercase tracking-wide">
									{resource.subject.name}
								</p>
							{/if}
							<div class="flex items-center gap-2">
								{#if resource.owner}
									<UserAvatar username={resource.owner.username} />
								{/if}
								<div class="flex flex-col">
									<h2 class="text-xl -mb-1">{resource.title}</h2>
									<a
										href="/user/{resource.owner?.username}"
										class="text-md text-zinc-500 hover:text-zinc-400"
										onclick={(e) => e.stopPropagation()}
									>
										@{resource.owner?.username}
									</a>
								</div>
							</div>
							{#if resource.files?.length}
								<div class="rounded-none overflow-hidden">
									{#if resource.files.length > 1}
										<div
											class="bg-yellow-200 border border-yellow-300 w-full h-36 justify-center flex items-center"
										>
											<FolderIcon weight="fill" class="size-24 text-yellow-500 mr-2" />
										</div>
									{:else if isPdf(getFirstFileExt(resource))}
										<div class="border border-zinc-300">
											<PdfThumbnail
												url="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/files/{resource
													.files[0].id}/download"
											/>
										</div>
									{:else if isImage(getFirstFileExt(resource))}
										<img
											class="border border-zinc-300"
											src="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/files/{resource
												.files[0].id}/download"
											alt="imagen del recurso"
										/>
									{:else if isMarkdown(getFirstFileExt(resource))}
										<div
											class="border border-zinc-300 w-full h-100 overflow-hidden pointer-events-none"
										>
											<MarkdownViewer
												url="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/files/{resource
													.files[0].id}/download"
											/>
										</div>
									{:else}
										<div
											class="border border-zinc-300 bg-zinc-100 w-full h-24 justify-center flex items-center"
										>
											<QuestionIcon class="size-12 text-zinc-500 mr-2" />
											<p class="text-2xl text-zinc-500">Formato desconocido</p>
										</div>
									{/if}
								</div>
							{/if}
							<p class="text-zinc-700">{resource.description}</p>
							<div class="flex justify-end mb-4 gap-2">
								<a
									href="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/download"
									onclick={(e) => e.stopPropagation()}
								>
									<div
										class="bg-blue-200 border border-blue-100 hover:bg-blue-100 text-blue-900 px-3 py-1 flex items-center cursor-pointer rounded-none"
									>
										<DownloadSimpleIcon class="size-5 mr-2" />Descargar
									</div>
								</a>
							</div>
						</div>
					</div>
				{/if}
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
{/if}
