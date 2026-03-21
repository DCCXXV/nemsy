export interface User {
	id: number;
	email: string;
	username: string;
	hd?: string;
	studyId?: number;
	studyName?: string;
}

export interface Study {
	id: number;
	name: string;
}

export interface Subject {
	id: number;
	name: string;
	year?: string;
	pinned?: boolean;
}

export interface ResourceFile {
	id: number;
	fileName: string;
	fileSize: number;
}

export interface Resource {
	id: number;
	title: string;
	description?: string;
	files: ResourceFile[];
	createdAt: string;
	owner?: {
		id: number;
		username: string;
		email: string;
	};
	subject?: {
		id: number;
		name: string;
	};
}
