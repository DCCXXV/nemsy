<script lang="ts">
	import { PUBLIC_API_BASE_URL } from '$env/static/public';
	import type { Resource } from '$lib/types';
	import { Dialog } from 'bits-ui';
	import XIcon from 'phosphor-svelte/lib/XIcon';
	import DownloadSimpleIcon from 'phosphor-svelte/lib/DownloadSimpleIcon';

	import PdfViewer from '$lib/components/PdfViewer.svelte';
	import ImageViewer from '$lib/components/ImageViewer.svelte';
	import MarkdownViewer from '$lib/components/MarkdownViewer.svelte';
	import UserAvatar from '$lib/components/UserAvatar.svelte';

	let { resource }: { resource: Resource } = $props();

	let selectedFileIndex = $state(0);

	const selectedFile = $derived(resource.files?.[selectedFileIndex] ?? resource.files?.[0]);

	function getExtFromName(name: string): string {
		const dot = name.lastIndexOf('.');
		return dot >= 0 ? name.slice(dot + 1).toLowerCase() : '';
	}

	const ext = $derived(selectedFile ? getExtFromName(selectedFile.fileName) : '');
	const isImage = $derived(['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext));
	const isPdf = $derived(ext === 'pdf');
	const isMarkdown = $derived(ext === 'md');
	const fileUrl = $derived(
		selectedFile
			? `${PUBLIC_API_BASE_URL}/api/resources/${resource.id}/files/${selectedFile.id}/download`
			: ''
	);
</script>

<div class="flex flex-col md:flex-row h-full overflow-hidden">
	<div
		class="md:order-2 w-full md:w-72 shrink-0 relative flex flex-col overflow-y-auto p-2 gap-4 bg-zinc-50 border-b md:border-b-0 md:border-l border-zinc-300"
	>
		<Dialog.Close
			class="absolute top-2 right-2 p-1.5 text-red-600 bg-red-100 hover:text-red-700 hover:bg-red-200 cursor-pointer"
		>
			<XIcon class="size-4" />
		</Dialog.Close>
		<div class="flex items-center gap-2 min-w-0 pr-8">
			{#if resource.owner}
				<UserAvatar username={resource.owner.username} />
			{/if}
			<div class="flex flex-col min-w-0">
				<h2 class="text-xl text-zinc-900 leading-snug">{resource.title}</h2>
				<span class="text-sm text-zinc-500">@{resource.owner?.username}</span>
			</div>
		</div>
		{#if resource.files?.length > 1}
			<div class="flex flex-col gap-0.5">
				{#each resource.files as file, i (i)}
					<button
						onclick={() => (selectedFileIndex = i)}
						class="text-left text-xs px-2 py-2 truncate cursor-pointer {i === selectedFileIndex
							? 'bg-zinc-200 text-zinc-700'
							: 'text-zinc-600 hover:bg-zinc-100'}"
					>
						{file.fileName}
					</button>
				{/each}
			</div>
		{/if}
		{#if resource.description}
			<p class="text-sm text-zinc-700 leading-relaxed">{resource.description}</p>
		{/if}
		<a href="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/download" class="md:mt-auto">
			<div
				class="bg-blue-200 border border-blue-100 hover:bg-blue-100 text-blue-900 px-3 py-2 flex items-center cursor-pointer text-sm rounded-none"
			>
				<DownloadSimpleIcon class="size-4 mr-1" />Descargar
			</div>
		</a>
	</div>

	<div class="md:order-1 flex-1 flex flex-col overflow-hidden border-r border-zinc-300 bg-zinc-100">
		{#if isPdf}
			<PdfViewer url={fileUrl} />
		{:else if isImage}
			<ImageViewer src={fileUrl} />
		{:else if isMarkdown}
			<MarkdownViewer url={fileUrl} />
		{:else}
			<div class="flex-1 flex items-center justify-center text-zinc-400 text-sm">
				Sin previsualización
			</div>
		{/if}
	</div>
</div>
